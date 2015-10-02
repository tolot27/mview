# -*- perl -*-
# Copyright (C) 1996-2015 Nigel P. Brown
# $Id: tblastn.pm,v 1.10 2015/06/14 17:09:04 npb Exp $

###########################################################################
package NPB::Parse::Format::BLAST2::tblastn;

use NPB::Parse::Format::BLAST2::blastx;
use strict;

use vars qw(@ISA);

@ISA = qw(NPB::Parse::Format::BLAST2::blastx);


###########################################################################
package NPB::Parse::Format::BLAST2::tblastn::HEADER;

use vars qw(@ISA);

@ISA = qw(NPB::Parse::Format::BLAST2::blastx::HEADER);


###########################################################################
package NPB::Parse::Format::BLAST2::tblastn::SEARCH;

use vars qw(@ISA);

@ISA = qw(NPB::Parse::Format::BLAST2::blastx::SEARCH);


###########################################################################
package NPB::Parse::Format::BLAST2::tblastn::SEARCH::RANK;

use vars qw(@ISA);

@ISA = qw(NPB::Parse::Format::BLAST2::blastx::SEARCH::RANK);


###########################################################################
package NPB::Parse::Format::BLAST2::tblastn::SEARCH::MATCH;

use vars qw(@ISA);

@ISA = qw(NPB::Parse::Format::BLAST2::blastx::SEARCH::MATCH);


###########################################################################
package NPB::Parse::Format::BLAST2::tblastn::SEARCH::MATCH::SUM;

use vars qw(@ISA);

@ISA = qw(NPB::Parse::Format::BLAST2::blastx::SEARCH::MATCH::SUM);


###########################################################################
package NPB::Parse::Format::BLAST2::tblastn::SEARCH::MATCH::ALN;

use vars qw(@ISA);

@ISA = qw(NPB::Parse::Format::BLAST2::SEARCH::MATCH::ALN);

sub new {
    my $type = shift;
    my $self = new NPB::Parse::Format::BLAST2::SEARCH::MATCH::ALN(@_);
    my $text = new NPB::Parse::Record_Stream($self);

    $self->{'sbjct_frame'} = '';

    my $line;

    $line = $text->next_line(1);
    $line = $text->next_line(1);
    $line = $text->next_line(1);

    #warn "[$line]\n";

    #sbjct frame
    if ($line =~ /^\s*Frame\s*=\s+(\S+)\s*$/) {
        $self->{'sbjct_frame'} = $1;
    }

    #record paired orientations in MATCH list
    push @{$self->get_parent(1)->{'orient'}->{
				 $self->{'query_orient'} .
                                 $self->{'sbjct_orient'}
				}}, $self;
    bless $self, $type;
}

sub print_data {
    my ($self, $indent) = (@_, 0);
    my $x = ' ' x $indent;
    $self->SUPER::print_data($indent);
    printf "$x%20s -> %s\n",  'sbjct_frame',  $self->{'sbjct_frame'};
}

###########################################################################
package NPB::Parse::Format::BLAST2::tblastn::WARNING;

use vars qw(@ISA);

@ISA = qw(NPB::Parse::Format::BLAST::WARNING);


###########################################################################
package NPB::Parse::Format::BLAST2::tblastn::PARAMETERS;

use vars qw(@ISA);

@ISA = qw(NPB::Parse::Format::BLAST::PARAMETERS);


###########################################################################
1;
