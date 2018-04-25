# Copyright (C) 1996-2018 Nigel P. Brown

use strict;

###########################################################################
package Bio::Util::Math;

use Exporter;

use vars qw(@ISA @EXPORT_OK);

@ISA = qw(Exporter);

@EXPORT_OK = qw(min max);

#arithmetic min() function
sub min { return $_[0] < $_[1] ? $_[0] : $_[1] }

#arithmetic max() function
sub max { return $_[0] > $_[1] ? $_[0] : $_[1] }

###########################################################################
1;
