# Copyright (C) 1997-2017 Nigel P. Brown

###########################################################################
package Bio::MView::Build::Format::CLUSTAL;

use Bio::MView::Build::Align;

use strict;
use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Align);

#the name of the underlying NPB::Parse::Format parser
sub parser { 'CLUSTAL' }

sub parse {
    my $self = shift;
    my ($rank, $use, $id, $seq, @hit) = (0);

    return  unless defined $self->{scheduler}->next;

    foreach $id (@{$self->{'entry'}->parse(qw(ALIGNMENT))->{'id'}}) {

	$rank++;

        last  if $self->topn_done($rank);
        next  if $self->skip_row($rank, $rank, $id);

	#warn "KEEP: ($rank,$id)\n";

	$seq = $self->{'entry'}->parse(qw(ALIGNMENT))->{'seq'}->{$id};

	push @hit, new Bio::MView::Build::Row::CLUSTAL($rank, $id, '', $seq);
    }
    #map { $_->print } @hit;

    #free objects
    $self->{'entry'}->free(qw(ALIGNMENT));

    return \@hit;
}


###########################################################################
package Bio::MView::Build::Row::CLUSTAL;

use Bio::MView::Build::Row;

use strict;
use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Simple_Row);

sub rdb_row { my $self = shift; $self->rdb_row_no_description(@_); }


###########################################################################
1;
