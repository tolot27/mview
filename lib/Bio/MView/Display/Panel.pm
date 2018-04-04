# Copyright (C) 1997-2018 Nigel P. Brown

use strict;

###########################################################################
package Bio::MView::Display::Panel;

use Universal qw(max swap vmstat);
use Bio::MView::Display::Sequence;
use Bio::MView::Display::Ruler;
use Bio::MView::Display::Out::Text qw($LJUST $RJUST);

my $MINPOSWIDTH = 2;  #smallest ruler left/right position width
my $HSPACE      = 1;  #extra spaces between columns

my %Known_Track_Types = (
    'ruler'    => 1,
    'sequence' => 1,
    );

sub new {
    my $type = shift;
    die "${type}::new: missing arguments\n"  if @_ < 3;
    my ($par, $headers, $startseq) = @_;

    my $self = {};
    bless $self, $type;

    $self->{'par'}      = $par;
    $self->{'header'}   = $headers;

    $self->{'length'}   = $startseq->length;
    $self->{'forwards'} = $startseq->is_forwards;

    #start/stop, counting extent forwards
    $self->{'start'}    = $startseq->lo;
#   $self->{'stop'}     = $startseq->hi;
    $self->{'stop'}     = $self->{'start'} + $self->{'length'} - 1;

    $self->{'track'}    = [];  #display objects

    #warn "${type}::new: start= $self->{'start'}, stop= $self->{'stop'}, (fw= $self->{'forwards'})";

    #initial width of left/right sequence position as text
    my ($pos1, $pos2) = (length("$self->{'start'}"), length("$self->{'stop'}"));
    ($pos1, $pos2) = swap($pos1, $pos2)  unless $self->{'forwards'};

    $self->{'posnwidths'} = [max($pos1, $MINPOSWIDTH), max($pos2, $MINPOSWIDTH)];

    #initial label widths
    $self->{'labelwidths'} = [];
    for (my $i=0; $i < @{$par->{'labelflags'}}; $i++) {
        $self->{'labelwidths'}->[$i] = 0;
    }

    $self;
}

######################################################################
# public methods
######################################################################
sub length     { return $_[0]->{'length'} }
sub forwards   { return $_[0]->{'forwards'} }
sub posnwidth  { return $_[0]->{'posnwidths'}->[$_[1]] }
sub labelwidth { return $_[0]->{'labelwidths'}->[$_[1]] }

sub append {
    my $self = shift;

    #handle data rows
    foreach my $row (@_) {

        unless (exists $row->{'type'}) {
            warn "${self}::append: missing type in '$row'\n";
            next;
        }

        my $type = $row->{'type'};

        unless (exists $Known_Track_Types{$type}) {
            warn "${self}::append: unknown alignment type '$type'\n";
            next;
        }

        $type = ucfirst $type;

        my $o = construct_row($type, $self, $row);

        push @{$self->{'track'}}, $o;

        #update column widths seen so far in this panel
        for (my $i=0; $i < @{$self->{'labelwidths'}}; $i++) {
            $self->{'labelwidths'}->[$i] =
                max($self->{'labelwidths'}->[$i], $o->labelwidth($i));
        }
    }
    #vmstat("Panel::append done");
}

sub render_panel {
    my ($self, $par, $posnwidths, $labelwidths) = @_;

    return  unless @{$self->{'track'}};

    #no fieldwidths from caller? use own set
    if (! defined $posnwidths) {
        $posnwidths  = $self->{'posnwidths'};
        $labelwidths = $self->{'labelwidths'};
    }

    $par->{'chunk'} = $par->{'width'};
    $par->{'chunk'} = $self->{'length'}  if $par->{'chunk'} < 1;  #full width

    if (@{$self->{'header'}}) {
        $par->{'dev'}->render_tr_pre_begin;
        foreach my $s (@{$self->{'header'}}) {
            $par->{'dev'}->render_text($s);
        }
        $par->{'dev'}->render_tr_pre_end;
    }

    $par->{'dev'}->render_tr_pre_begin;
    $self->render_pane($par, $posnwidths, $labelwidths);
    $par->{'dev'}->render_tr_pre_end;

    $self->free_rows;  #garbage collect rows
}

######################################################################
# private methods
######################################################################
sub free_rows {
    #print "free: $_[0]\n";
    while (@{$_[0]->{'track'}}) {  #consume tracks
        my $o = shift @{$_[0]->{'track'}};
        $o = undef;
    }
}

#output a pane of par{'width'} chunks
sub render_pane {
    my ($self, $par, $posnwidths, $labelwidths) = @_;

    #need space for sequence position numbers?
    my $has_ruler = 0;
    foreach my $o (@{$self->{'track'}}) {
        $has_ruler = 1  if $o->is_ruler;
        $o->reset;
    }

    #vmstat("render pane");
    while (1) {
        last  unless $self->render_chunk($par, $has_ruler,
                                         $posnwidths, $labelwidths);
    }
    #vmstat("render pane done");
}

#output a single chunk
sub render_chunk {
    my ($self, $par, $has_ruler, $posnwidths, $labelwidths) = @_;

    #render each track's segment for this chunk
    foreach my $o (@{$self->{'track'}}) {

        my $seg = $o->next_segment($par);

        return 0  unless defined $seg;  #all chunks done

        #label0: rownum
        if ($par->{'labelflags'}->[0] and $labelwidths->[0]) {
            $par->{'dev'}->render_rownum($labelwidths->[0], $o->label(0));
            $par->{'dev'}->render_hspace($HSPACE);
        }

        #label1: identifier
        if ($par->{'labelflags'}->[1] and $labelwidths->[1]) {
            $par->{'dev'}->render_identifier($labelwidths->[1], $o->label(1),
                                             $o->{'url'});
            $par->{'dev'}->render_hspace($HSPACE);
        }

        #label2: description
        if ($par->{'labelflags'}->[2] and $labelwidths->[2]) {
            $par->{'dev'}->render_description($labelwidths->[2], $o->label(2));
            $par->{'dev'}->render_hspace($HSPACE);
        }

        #labels3-7: info
        for (my $i=3; $i < @$labelwidths; $i++) {
            if ($par->{'labelflags'}->[$i] and $labelwidths->[$i]) {
                $par->{'dev'}->render_annotation($labelwidths->[$i],
                                                 $o->label($i));
                $par->{'dev'}->render_hspace($HSPACE);
            }
        }

        #left position
        if ($has_ruler) {
            $par->{'dev'}->render_position($RJUST, $posnwidths->[0],
                                           $seg->[0], $o->is_ruler,
                                           $par->{'bold'})
        }
        $par->{'dev'}->render_hspace($HSPACE);

        #sequence string
        $par->{'dev'}->render_sequence($seg->[2], $par->{'bold'});
        $par->{'dev'}->render_hspace($HSPACE);

        #right position
        if ($has_ruler) {
            $par->{'dev'}->render_position($LJUST, $posnwidths->[1],
                                           $seg->[1], $o->is_ruler,
                                           $par->{'bold'});
        }
        $par->{'dev'}->render_newline;
    }

    #blank between chunks
    $par->{'dev'}->render_text("\n");

    return 1;  #end of chunk
}

######################################################################
# private class methods
######################################################################
sub construct_row {
    my ($type, $owner, $data) = @_;
    no strict 'refs';
    my $row = "Bio::MView::Display::$type"->new($owner, $data);
    use strict 'refs';
    return $row;
}

######################################################################
# debug
######################################################################
#sub DESTROY { print "destroy: $_[0]\n" }

sub dump {
    my $self = shift;
    foreach my $k (sort keys %$self) {
        warn sprintf "%15s => %s\n", $k, $self->{$k};
    }
    map { $_->dump } @{$self->{'track'}};
}

###########################################################################
1;
