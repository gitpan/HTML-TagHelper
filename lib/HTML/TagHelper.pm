package HTML::TagHelper;

use warnings;
use strict;
use base qw/Class::Accessor::Fast/;
use HTML::Element;
use Carp;

=head1 NAME

HTML::TagHelper - Generate HTML tags in an easy way

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

    use HTML::TagHelper;

    my $th = HTML::TagHelper->new();
		print $th->image_tag(...);
		print $th->link_to(...);
		my $th->text_field_tag(...);
		my $th->select_tag(...);
		my $th->options_for_select(...);


=head1 DESCRIPTION

The module contains some code generators to easily create tags for links, images, select-tags etc.

This is mostly a port of the Ruby on Rails helper tags for use in L<Catalyst>.

=head1 FUNCTIONS

=head2 image_tag

=over 4

=item $th->image_tag($src, \%options)

Create an img html element pointing to C<$src>.

Required options are:

C<src>: Specifies the link to the image to be displayed.

Addtional options are:

C<alt>: An alt text for the tag. B default this is the filename of C<src> without extension.

C<escape_html>: Whether or not you want to escape the outputted html (default is 1).

Besides this options, you can enter any option you want as an attribute on the tag, e.g. class, id etc.

=back

=cut

sub image_tag {
	my ($self, $src, $options) = @_;
	croak("You need to specify a source for the image tag") unless $src;
	
	$options ||= {};
	my %options = (
			alt => ($src =~ /([^\/]+)\.\w+$/)[0],
			escape_html => 1,
			src => $src,
			%$options,
			);
	
	my $entities = ($options{escape_html}) ? '<>&' : "";
	delete $options{escape_html};
	my $tag = HTML::Element->new('img', %options);
	my $html_tag = $tag->as_HTML($entities);
	$html_tag =~ s/\n//gs;
	return $html_tag
}

=head2 link_to

=over 4

=item $th->link_to($content, \%options)

Create an 'a' html element with the flexibility to make popups, post to the url instead, ask for confirmation etc.

Required options are:

C<content>: Specifies what the visible text is to the user (the stuff between <a> and </a>).

Addtional options are:

C<href>: Where the link should point to (default is #).

C<escape_html>: Whether or not you want to escape the outputted html (default is 0).

C<confirm>: The text that will popup in a confirm box.

C<popup>: Opens a new window where the source is href.

C<method>: If you want to use 'POST' instead of 'GET'.

Besides this options, you can enter any option you want as an attribute on the tag, e.g. class, id etc.

=back

=cut

sub link_to {
	my ($self, $content, $html_options) = @_;
	croak("You need to specify content for the link") unless $content;
	
	my $href = "";
	my $tagoptions = "";
	
	$html_options ||= {};
	my %options = (
		href => "#",
		escape_html => 0,
		%$html_options,
		);
		
	if (%options) {
		$href = $options{href};
		$self->_convert_options_to_javascript(\%options, $options{href});
		$self->_tag_options(\%options);
	}

	my $entities = ($options{escape_html}) ? '<>&' : "";
	delete $options{escape_html};
	my $tag = HTML::Element->new('a');
	$tag->attr('href', $href);
	while ( my ($key, $value) = each %options ) {
		$tag->attr($key, $value);
	}
	$tag->push_content( ref $content eq 'ARRAY' ? @{$content} : $content );
	my $html_tag = $tag->as_HTML($entities);
	$html_tag =~ s/\n//gs;
	return $html_tag;
}

=head2 text_field_tag

=over 4

=item $th->text_field_tag($name, \%options)

Create a text input html element.

Required options are:

C<name>: The content of the name attribute on the tag

Addtional options are:

C<id>: The content of the id attribute on the tag (defaults to the value of C<name>).

C<value>: The value of the tag

Besides this options, you can enter any option you want as an attribute on the tag, e.g. class, id etc.

=back

=cut

sub text_field_tag {
	my ($self, $name, $options) = @_;
	croak("You need to specify a name for the text field") unless $name;
	
	$options ||= {};
	my %options = (
		name => $name,
		id => $name,
		type => "text",
		%$options,
		);
	
	my $tag = HTML::Element->new('input', %options);
	my $html_tag = $tag->as_HTML("");
	$html_tag =~ s/\n//gs;
	return $html_tag;
}

=head2 select_tag

=over 4

=item $th->select_tag($name, \@options, \%html_options)

Create a select html element.

Required options are:

C<name>: The content of the name attribute on the tag

The options array must contain either the output of C<options_for_select> or an array of hashes with title and value as keys.

Addtional html_options are:

C<id>: The content of the id attribute on the tag (defaults to the value of C<name>).

Besides this html_option, you can enter any option you want as an attribute on the tag, e.g. class, id etc.

=back

=cut

sub select_tag {
	my ($self, $name, $options, $html_options) = @_;
	croak("You need to specify a name for the selector") unless $name;
	
	if (defined($options) && ref $options eq 'ARRAY') {
		my $value = delete $html_options->{value};
		$options = $self->options_for_select($options, $value);
	}
	
	$html_options ||= {};
	my %html_options = (
		name => $name,
		id => $name,
		%$html_options,
		);
	
	my $tag = HTML::Element->new('select', %html_options);
	$tag->push_content($options) if defined($options);
	return $tag->as_HTML("");
}

=head2 options_for_select

=over 4

=item $th->options_for_select(\@options)

Create all options html elements to put inside C<select_tag>.

Required options are:

C<options>: This is an array of hashes, where the title pair will be used for content of the tag, and the value pair will be used for value.

Example:

    $th->options_for_select( [{title => "Option 1", value="option1"}, {title => "Option 2", value => "option2"}] );

=back

=cut 

sub options_for_select {
	my ($self, $optionlist, $selected) = @_;
	$selected = () unless defined $selected;
	my $options = "";
	my $content;
	my $tag;
	
	foreach my $optionset (@$optionlist) {
		$content = delete $optionset->{title};
		$optionset->{selected} = "true" if (grep { $_ eq $optionset->{value} } @$selected);
		$tag = HTML::Element->new('option', %$optionset);
		$tag->push_content($content);
		$options .= $tag->as_HTML("")."\n";
	}
	return $options;
}

=head2 date_select_tag

=over 4

=item $th->date_select_tag($name, \%options)

Create 3 select html element - one for day, one for month and one for year.

Required options are:

C<name>: The content of the name attribute on the tag. They are all post-fixed with "day", "month" or "year"

The options array must contain either the output of C<options_for_select> or an array of hashes with title and value as keys.

Addtional options are:

C<year_start>: Which year should be the first option. Defaults to DateTime->now->year

C<year_end>: Which your should be the last option. Default to C<start_year> + 5

C<id>: The content of the id attribute on the tag (defaults to the value of C<name>).

C<class>: The content of the class attributes on the tags.

Besides this html_option, you can enter any option you want as an attribute on the tag, e.g. class, id etc.

=back

=cut

sub date_select_tag {
	my ($self, $name, $options) = @_;
	croak("You need to specify a name for the selector") unless $name;
		
	$options ||= {};
	my %html_options = (
		name => $name,
		id => $name,
		year_start => DateTime->now->year,
		year_end => DateTime->now->year + 5,
		selected_date => DateTime->now,
		%$options,
		);
	
	my $sel_year = $html_options{selected_date}->year;
	my $sel_month = $html_options{selected_date}->month;
	my $sel_day = $html_options{selected_date}->day;
	delete $html_options{selected_date};
	my $year_start = delete $html_options{year_start};
	my $year_end = delete $html_options{year_end};
	my $year_name = $html_options{name} . "_year";
	my $year_id = $html_options{id} . "_year";
	my $month_name = $html_options{name} . "_month";
	my $month_id = $html_options{id} . "_month";
	my $day_name = $html_options{name} . "_day";
	my $day_id = $html_options{id} . "_day";
	delete $html_options{name};
	delete $html_options{id};
	delete $html_options{year_start};
	delete $html_options{year_end};
	my $year_options = "";
	my $tmp_option;
	foreach my $year ($year_start .. $year_end) {
		$tmp_option = HTML::Element->new('option');
		$tmp_option->attr('value', $year);
		$tmp_option->attr('selected', 'true') if ($year == $sel_year);
		$tmp_option->push_content($year);
		$year_options .= $tmp_option->as_HTML("");
	}
	
	my $month_options = "";
	foreach my $month (1 .. 12) {
		$tmp_option = HTML::Element->new('option');
		$tmp_option->attr('value', $month);
		$tmp_option->attr('selected', 'true') if ($month == $sel_month);
		$tmp_option->push_content($month);
		$month_options .= $tmp_option->as_HTML("");
	}
	
	my $day_options = "";
	foreach my $day (1 .. 31) {
		$tmp_option = HTML::Element->new('option');
		$tmp_option->attr('value', $day);
		$tmp_option->attr('selected', 'true') if ($day == $sel_day);
		$tmp_option->push_content($day);
		$day_options .= $tmp_option->as_HTML("");
	}
	
	my $date_select = "";
	
	my $day_tag = HTML::Element->new('select', %html_options);
	$day_tag->attr('id', $day_id);
	$day_tag->attr('name', $day_name);
	$day_tag->push_content($day_options);
	$date_select .= $day_tag->as_HTML("");
	
	my $month_tag = HTML::Element->new('select', %html_options);
	$month_tag->attr('id', $month_id);
	$month_tag->attr('name', $month_name);
	$month_tag->push_content($month_options);
	$date_select .= $month_tag->as_HTML("");
	
	my $year_tag = HTML::Element->new('select', %html_options);
	$year_tag->attr('id', $year_id);
	$year_tag->attr('name', $year_name);
	$year_tag->push_content($year_options);
	$date_select .= $year_tag->as_HTML("");
	
	return $date_select;
}

sub _convert_options_to_javascript {
	my ($self, $html_options, $url) = @_;
	my $confirm = delete $html_options->{confirm};
	my $popup = delete $html_options->{popup};
	my $method = delete $html_options->{method};
	my $href = delete $html_options->{href};
	
	$html_options->{onclick}
		= ( $popup && $method )   ? croak("You can't use :popup and :method in the same link\n")
	  : ( $confirm && $popup )  ? "if (" . $self->_confirm_javascript_function($confirm) . ") { " . $self->_popup_javascript_function($popup) . " };return false;"
	  : ( $confirm && $method ) ? "if (" . $self->_confirm_javascript_function($confirm) . ") { " . $self->_method_javascript_function($method) . " };return false;"
	  : ( $confirm )            ? "return " . $self->_confirm_javascript_function($confirm) . ";"
		: ( $method )             ? $self->_method_javascript_function($method, $url, $href) . "return false;"
		: ( $popup )              ? $self->_popup_javascript_function($popup) . ' return false;'
		:                           $html_options->{onclick};
	return $html_options;
}

sub _confirm_javascript_function {
	my ($self, $confirm) = @_;
	return "confirm('" . $self->_escape_javascript($confirm) . "')";
}

sub _popup_javascript_function {
	my ($self, $popup) = @_;
	return (ref $popup eq 'ARRAY') ? "window.open(this.href, '" . shift (@$popup) . "', '" . pop (@$popup) . "');" : "window.open(this.href);";
}

sub _method_javascript_function {
	my ($self, $method, $url , $href) = @_;
	$url = "" unless defined $url;
	$href = undef unless defined $href;
	my $action = ($href && length($url) > 0) ? "'" . $url . "'" : "this.href";
	my $submit_function = "var f = document.createElement('form'); f.style.display = 'none'; " .
  											"this.parentNode.appendChild(f); f.method = 'POST'; f.action = " . $action . ";";
	unless ($method eq 'post') {
		$submit_function .= "var m = document.createElement('input'); m.setAttribute('type', 'hidden'); ";
		$submit_function .= "m.setAttribute('name', '_method'); m.setAttribute('value', '" . $method . "'); f.appendChild(m);";
	}
	
	$submit_function .= "f.submit();";
	return $submit_function;
}

sub _tag_options {
	my ($self, $options, $escape) = @_;
	$escape = 1 unless defined $escape;
	
	my @boolean_attributes = qw/disabled readonly multiple/;
	
	if ($options) {
		if ($escape) {
			while ( my ($key, $value) = each %$options ) {
				next unless ($value);
				$value = (grep {$_ eq $key} @boolean_attributes) ? $key : $value;
				$options->{$key} = $value;
			}
		}
	}
	return $options;
}

sub _escape_javascript {
	my ($self, $javascript) = @_;
	
	$javascript ||= '';
	$javascript =~ s|\\|\0\0|g;
	$javascript =~ s|</|<\/|g;
	$javascript =~ s|\r\n|\\n|g;
	$javascript =~ s|["']||g;
	return $javascript;
}

=head1 AUTHOR

Gitte Wange Olrik, C<< <gitte at olrik.dk> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-html-taghelper at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=HTML-TagHelper>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc HTML::TagHelper


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=HTML-TagHelper>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/HTML-TagHelper>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/HTML-TagHelper>

=item * Search CPAN

L<http://search.cpan.org/dist/HTML-TagHelper>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2008 Gitte Wange Olrik, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of HTML::TagHelper
