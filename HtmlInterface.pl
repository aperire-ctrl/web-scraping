#! c:/perl/bin/perl

use strict;
use UNIVERSAL qw(isa);
use HTML::TreeBuilder;
use vars qw(%htmlList $nodeNbr);
$" = "\n";

# Subroutine to create a list of nodes for a given file
sub retHtmlList {
my $fileName = shift; 
my $tree = HTML::TreeBuilder->new; # empty tree

    	
	#Initialize
	undef %htmlList;
	$nodeNbr = 0;
	
	# Parse the html file
	$tree->parse_file($fileName);

	# Listify the nodes 
	# The traversal of the tree is in a depth first fashion
	$tree->traverse(\&makeList,0);

	# Now that we're done with it, we must destroy it.
	$tree = $tree->delete;

	return %htmlList;
}

# Subroutine to create a list of nodes for a given tree
sub retHtmlListFromTree {
my ($tree) = @_;

	#Initialize
	undef %htmlList;
	$nodeNbr = 0;
	
	# Listify the nodes 
	# The traversal of the tree is in a depth first fashion
	$tree->traverse(\&makeList,0);

	# Now that we're done with it, we must destroy it.
	#$tree = $tree->delete;

	return %htmlList;
}

# Subroutine to create a tree for a given file
sub retHtmlTree {
my $file_name = shift; 
my $tree = HTML::TreeBuilder->new; # empty tree

	# Parse the html file
	$tree->parse_file($file_name);

	return $tree;
}

# Subroutine to create a list of nodes for a given document
sub retHtmlDocList {
my $document = shift; 
my $tree = HTML::TreeBuilder->new; # empty tree

	# Parse the html document 
	$tree->parse($document);

	# Listify the nodes 
	$tree->traverse(\&makeList,0);

	# Now that we're done with it, we must destroy it.
	$tree = $tree->delete;

	return %htmlList;
}

# Subroutine to create a tree for a given document
sub retHtmlDocTree {
my $document = shift; 
my $tree = HTML::TreeBuilder->new; # empty tree

	# Parse the html document
	$tree->parse($document);

	return $tree;
}
