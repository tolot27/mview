# -*- perl -*-
# Copyright (C) 1996-2013 Nigel P. Brown

###########################################################################
package Bio::Parse::Format::FASTA2::ssearch;

use Bio::Parse::Format::FASTA2;
use strict;

use vars qw(@ISA);

@ISA = qw(Bio::Parse::Format::FASTA2);

sub new { my $self=shift; $self->SUPER::new(@_) }


###########################################################################
package Bio::Parse::Format::FASTA2::ssearch::HEADER;

use vars qw(@ISA);

@ISA   = qw(Bio::Parse::Format::FASTA2::HEADER);

sub new {
    my $self = shift;
    $self = $self->SUPER::new(@_);
    #assume the query identifier is the same as the query filename
    if ($self->{query} eq '' and $self->{queryfile} ne '') {
	$self->{query} = $self->{queryfile};
    }
    return $self;
}

###########################################################################
package Bio::Parse::Format::FASTA2::ssearch::RANK;

use vars qw(@ISA);

@ISA   = qw(Bio::Parse::Format::FASTA::RANK);

sub new {
    my $type = shift;
    if (@_ < 2) {
	#at least two args, ($offset, $bytes are optional).
	Bio::Message::die($type, "new() invalid arguments (@_)");
    }
    my ($parent, $text, $offset, $bytes) = (@_, -1, -1);
    my ($self, $line, $record);
    
    $self = new Bio::Parse::Record($type, $parent, $text, $offset, $bytes);
    $text = new Bio::Parse::Record_Stream($self);

    #ranked search hits
    while (defined ($line = $text->next_line)) {
	
	next    if $line =~ /$Bio::Parse::Format::FASTA2::RANK_START/o;

	if($line =~ /^
	   \s*
	   ([^\s]+)                #id
	   \s+
	   (.*)                    #description: possibly empty
	   \s+
	   \(\s*(\S+)\)            #hit sequence length
           \s*
	   (?:\[(\S)\])?           #frame
	   \s*
	   (\S+)                   #s-w score
	   \s+
	   (\S+)                   #Z-score
	   \s+
	   (\S+)                   #E-value
	   \s*
	   $/xo) {
	    
	    $self->test_args(\$line, $1, $3, $5,$6,$7);
	    
	    push(@{$self->{'hit'}},
		 { 
		  'id'      => Bio::Parse::Record::clean_identifier($1),
		  'desc'    => $2,
		  #ignore $3
		  'frame'   => Bio::Parse::Format::FASTA::parse_frame($4),
		  'orient'  => Bio::Parse::Format::FASTA::parse_orient($4),
		  'score'   => $5,
		  'zscore'  => $6,
		  'expect'  => $7,
		 });
	    next;
	}
    
	#blank line or empty record: ignore
	next    if $line =~ /$Bio::Parse::Format::FASTA2::NULL/o;
	
	#default
	$self->warn("unknown field: $line");
    }
    $self;
}


###########################################################################
package Bio::Parse::Format::FASTA2::ssearch::TRAILER;

use vars qw(@ISA);

@ISA   = qw(Bio::Parse::Format::FASTA::TRAILER);


###########################################################################
package Bio::Parse::Format::FASTA2::ssearch::MATCH;

use vars qw(@ISA);

@ISA   = qw(Bio::Parse::Format::FASTA::MATCH);


###########################################################################
package Bio::Parse::Format::FASTA2::ssearch::MATCH::SUM;

use vars qw(@ISA);
use Bio::Util::Regexp;

@ISA   = qw(Bio::Parse::Format::FASTA::MATCH::SUM);

sub new {
    my $type = shift;
    if (@_ < 2) {
	#at least two args, ($offset, $bytes are optional).
	Bio::Message::die($type, "new() invalid arguments (@_)");
    }
    my ($parent, $text, $offset, $bytes) = (@_, -1, -1);
    my ($self, $line, $record);
    
    $self = new Bio::Parse::Record($type, $parent, $text, $offset, $bytes);
    $text = new Bio::Parse::Record_Stream($self);

    $line = $text->next_line;
	
    if ($line =~ /^
	>*
	(\S+)                      #id
	\s+
	(.*)                       #description: possibly empty
	\s+
	\(\s*(\d+)\s*(?:aa|nt)\)   #length
	\s*
	$/xo) {

	$self->test_args(\$line, $1, $3);

	(
	 $self->{'id'},
	 $self->{'desc'},
	 $self->{'length'},
	) = (Bio::Parse::Record::clean_identifier($1),
	     Bio::Parse::Record::strip_english_newlines($2), $3);
    } else {
	$self->warn("unknown field: $line");
    }

    $line = $text->next_line;
    
    if ($line =~ /^
	\s*
	z-score\:\s*(\S+)      #z
	\s*
	Expect\:\s*(\S+)       #E
	\s*
	$/xo) {

	$self->test_args(\$line,$1,$2);

	(
	 $self->{'zscore'},
	 $self->{'expect'},
	) = ($1,$2);
    } else {
	$self->warn("unknown field: $line");
    }
    
    $line = $text->next_line;

    if ($line =~ /^
	(?:Smith-Waterman\s+score:\s*(\d+);)?    #sw score
	\s*($RX_Ureal)%                          #percent identity
	\s*identity\s+in\s+(\d+)                 #overlap length
	\s+(?:aa|nt)\s+overlap
	\s*
	$/xo) {

	$self->test_args(\$line,$2,$3);
	
	(
	 $self->{'score'},
	 $self->{'id_percent'},
	 $self->{'overlap'},
	) = ((defined $1 ? $1 : 0), $2, $3);
    } else {
	$self->warn("unknown field: $line");
    }
    
    $self;
}


###########################################################################
package Bio::Parse::Format::FASTA2::ssearch::MATCH::ALN;

use vars qw(@ISA);

@ISA   = qw(Bio::Parse::Format::FASTA2::MATCH::ALN);


###########################################################################
1;
