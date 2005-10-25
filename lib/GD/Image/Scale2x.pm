package GD::Image::Scale2x;

=head1 NAME

GD::Image::Scale2x - Implementation of the Scale2x algorithm for the GD library

=head1 SYNOPSIS

	use GD;
	use GD::Image::Scale2x;

	# load an image
	my $image = GD::Image->new( 'file.png' );

	# scale2x, 3x, and 4x
	my $scaled2x = $image->scale2x;
	my $scaled3x = $image->scale3x;
	my $scaled4x = $image->scale4x;

	# scale a certain area
	# (10, 10) to (30, 30)
	my $scaled = $image->scale2x( 10, 10, 20, 20 );

=head1 DESCRIPTION

This module implements the Scale2x algorithm (as well as 3x and 4x). From the Scale2x web site:

	Scale2x is real-time graphics effect able to increase the size of small bitmaps
	guessing the missing pixels without interpolating pixels and blurring the images.

The algorithm itself is explained at http://scale2x.sourceforge.net/algorithm.html. You can see
some example results by looking through the test directory.

=cut

use strict;
use warnings;

our $VERSION = '0.02';

=head1 METHODS

=head2 scale2x( [ $source_x, $source_y, $width, $height ] )

Takes an image and produces one twice a big. From the Scale2x web site:

	The effect works repeating a computation pattern for every pixel of the
	original image. The pattern starts from a square of 9 pixels and expands
	the central pixel computing 4 new pixels.

You can specify a portion of the original image by specifying a source x and y plus
a width and height.

=head2 scale3x( [ $source_x, $source_y, $width, $height ] )

A similar algorithm to scale2x, except that it produces a 9-pixel result.

=head2 scale4x( [ $source_x, $source_y, $width, $height ] )

Same as scale2x done twice over.

=head1 SEE ALSO

=over 4 

=item * GD

=item * http://scale2x.sourceforge.net/

=back

=head1 AUTHOR

=over 4 

=item * Brian Cassidy E<lt>bricas@cpan.orgE<gt>

=back

=head1 COPYRIGHT AND LICENSE

Copyright 2005 by Brian Cassidy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

package GD::Image;

use strict;
use warnings;

my $result = {
	2 => [
		{ x => 0, y => 0 },
		{ x => 1, y => 0 },
		{ x => 0, y => 1 },
		{ x => 1, y => 1 }
	],
	3 => [
		{ x => 0, y => 0 },
		{ x => 1, y => 0 },
		{ x => 2, y => 0 },
		{ x => 0, y => 1 },
		{ x => 1, y => 1 },
		{ x => 2, y => 1 },
		{ x => 0, y => 2 },
		{ x => 1, y => 2 },
		{ x => 2, y => 2 }
	]
};

sub scale2x {
	my $self = shift;

	return $self->_scale( 2, @_ );	
}

sub scale3x {
	my $self = shift;

	return $self->_scale( 3, @_ );	
}

sub scale4x {
	my $self = shift;

	my $image = $self->scale2x( @_ );
	return $image->scale2x;
}

sub _scale {
	my $self     = shift;
	my $scale    = shift;
	my $source_x = shift || 0;
	my $source_y = shift || 0;
	my $source_w = shift;
	my $source_h = shift;

	unless( $source_w ) {
		( $source_w, $source_h ) = $self->getBounds;
		$source_w -= $source_x;
		$source_h -= $source_y;
	}

	my $image   = GD::Image->new( $source_w * $scale, $source_h * $scale );
	my $bound_x = $source_w - 1;
	my $bound_y = $source_h - 1;

	my @palette;
	for my $y ( $source_y..$bound_y ) {
		for my $x ( $source_x..$bound_x ) {
			my $x_plus  = ( $x + 1 > $bound_x  ? $x : $x + 1 );
			my $x_minus = ( $x - 1 < $source_x ? $x : $x - 1 );
			my $y_plus  = ( $y + 1 > $bound_y  ? $y : $y + 1 );
			my $y_minus = ( $y - 1 < $source_y ? $y : $y - 1 );

			# 0 1 2 #
			# 3 4 5 # 4 => x, y
			# 6 7 8 #

			my @pixels = (
				$self->getPixel( $x_minus, $y_minus ),
				$self->getPixel( $x, $y_minus ),
				$self->getPixel( $x_plus, $y_minus ),
				$self->getPixel( $x_minus, $y ),
				$self->getPixel( $x, $y ),
				$self->getPixel( $x_plus, $y ),
				$self->getPixel( $x_minus, $y_plus ),
				$self->getPixel( $x, $y_plus ),
				$self->getPixel( $x_plus, $y_plus )
			);

			my @E = _calculate_scale( $scale, \@pixels );

			my $scaledx = $x * $scale;
			my $scaledy = $y * $scale;

			for( 0..$#E ) {
				unless( $palette[ $E[ $_ ] ] ) {
					$palette[ $E[ $_ ] ] = $image->colorAllocate( $self->rgb( $E[ $_ ] ) );
				}

				$image->setPixel( $scaledx + $result->{ $scale }->[ $_ ]->{ x }, $scaledy + $result->{ $scale }->[ $_ ]->{ y }, $palette[ $E[ $_ ] ] );
			}
		}
	}

	return $image;
}

sub _calculate_scale {
	my $scale  = shift;
	my $pixels = shift;

	my @E;
	if( $scale == 2 ) {
		if( $pixels->[ 1 ] != $pixels->[ 7 ] && $pixels->[ 3 ] != $pixels->[ 5 ] ) {
			$E[ 0 ] = ( $pixels->[ 3 ] == $pixels->[ 1 ] ? $pixels->[ 3 ] : $pixels->[ 4 ] );
			$E[ 1 ] = ( $pixels->[ 1 ] == $pixels->[ 5 ] ? $pixels->[ 5 ] : $pixels->[ 4 ] );
			$E[ 2 ] = ( $pixels->[ 3 ] == $pixels->[ 7 ] ? $pixels->[ 3 ] : $pixels->[ 4 ] );
			$E[ 3 ] = ( $pixels->[ 7 ] == $pixels->[ 5 ] ? $pixels->[ 5 ] : $pixels->[ 4 ] );
		}
		else {
			@E = ( $pixels->[ 4 ] ) x 4;
		}
	}
	elsif( $scale == 3 ) {
		if( $pixels->[ 1 ] != $pixels->[ 7 ] && $pixels->[ 3 ] != $pixels->[ 5 ] ) {
			$E[ 0 ] = ( $pixels->[ 3 ] == $pixels->[ 1 ] ? $pixels->[ 3 ] : $pixels->[ 4 ] );
			$E[ 1 ] = (
					( $pixels->[ 3 ] == $pixels->[ 1 ] && $pixels->[ 4 ] != $pixels->[ 2 ] ) ||
					( $pixels->[ 1 ] == $pixels->[ 5 ] && $pixels->[ 4 ] != $pixels->[ 0 ] )
					? $pixels->[ 1 ] : $pixels->[ 4 ]
			);
			$E[ 2 ] = ( $pixels->[ 1 ] == $pixels->[ 5 ] ? $pixels->[ 5 ] : $pixels->[ 4 ] );
			$E[ 3 ] = (
					( $pixels->[ 3 ] == $pixels->[ 1 ] && $pixels->[ 4 ] != $pixels->[ 6 ] ) ||
					( $pixels->[ 3 ] == $pixels->[ 7 ] && $pixels->[ 4 ] != $pixels->[ 0 ] )
					? $pixels->[ 3 ] : $pixels->[ 4 ]
			);
			$E[ 4 ] = $pixels->[ 4 ];
			$E[ 5 ] = (
					( $pixels->[ 1 ] == $pixels->[ 5 ] && $pixels->[ 4 ] != $pixels->[ 8 ] ) ||
					( $pixels->[ 7 ] == $pixels->[ 5 ] && $pixels->[ 4 ] != $pixels->[ 2 ] )
					? $pixels->[ 5 ] : $pixels->[ 4 ]
			);
			$E[ 6 ] = ( $pixels->[ 3 ] == $pixels->[ 7 ] ? $pixels->[ 3 ] : $pixels->[ 4 ] );
			$E[ 7 ] = (
					( $pixels->[ 3 ] == $pixels->[ 7 ] && $pixels->[ 4 ] != $pixels->[ 8 ] ) ||
					( $pixels->[ 7 ] == $pixels->[ 5 ] && $pixels->[ 4 ] != $pixels->[ 6 ] )
					? $pixels->[ 7 ] : $pixels->[ 4 ]
			);
			$E[ 8 ] = ( $pixels->[ 7 ] == $pixels->[ 5 ] ? $pixels->[ 5 ] : $pixels->[ 4 ] );
		}
		else {
			@E = ( $pixels->[ 4 ] ) x 9;
		}
	}

	return @E;
}

1;