use strict;
use Tk;
use Tk::BrowseEntry;
use English;
use Carp;
use Mysql;
use Tk::Frame;
use Tk::Balloon;
use Tk::DialogBox;
require 'dbInterface.pl';
require 'HtmlInterface.pl';

# Interface function from an external program to extract 
# records from an HTML page
sub extractRecords {

	#my ($siteName, $document) = @_; 
	my ($dbh, $siteName, $file) = @_; 

	my $docTree;
	my @mandatoryFldIds;
	my @fldIds;
	my $fldId;
	my $fldDef;
	my $name;
	my $depth;
	my $tagSeq;
	my $type;
	my @depth;
	my @tagSeq;
	my $relPos;
	my $relPosAdj;
	my $minLen;
	my $minLenAdj;
	my $keywords;
	my $omitwords;
	my $i;
	my $recordNbr;
	my $fldNbr;
	my %recHash;
	my $hasAllMandatoryFlds;
	my @mandatoryFldIds;
	my $firstFldNodeNbr;
	my $nodeNbr;
	my $seperatorTag;
	my @nodes;
	my $nodeDiff;
	my $fldName;
	my %masterHash;
	my $value;
	my $node;
	my $ref;


	# Make a tree of the HTML document 
	#$docTree=&retHtmlDocTree($document);
	$docTree=&retHtmlTree($file);

	# Get the mandatory field ids for this site
	@mandatoryFldIds=&dbGetMandatoryFldIds($dbh, $siteName);

	# Get all field ids for this site
	@fldIds=&dbGetFldIds($dbh, $siteName);

	# Extract data from the tree for each field 
	foreach $fldId (@fldIds) {

		# Get the field definition from the FINALVALUES table  
		$fldDef=&dbGetFldDef($dbh, $siteName, $fldId);

		# Get the field definitions
		$depth=$fldDef->{"DEPTH"};
		$tagSeq=$fldDef->{"TAGSEQ"};
		$type=$fldDef->{"FLDTYPE"};
		$relPos=$fldDef->{"RELPOS"};
		$minLen=$fldDef->{"MINLEN"};
		$keywords=$fldDef->{"KEYWORDS"};
		$omitwords=$fldDef->{"OMITWORDS"};
		$relPosAdj=$fldDef->{"RELPOSADJ"};
		$minLenAdj=$fldDef->{"MINLENADJ"};

		# Get the depth and tagseq values
		@depth=split /;/, $depth;
		@tagSeq=split /:/, $tagSeq;

		$i=0;
		foreach (@depth) {

			# Call the extactor function
			@nodes=&identifyNode($docTree, $depth[$i], 
							$tagSeq[$i], $type, $keywords, $omitwords);

			# Put the nodes in the master hash
			foreach (@nodes) {
				if ( (length $_->{"Text"})  >= $minLen and 
							(length $_->{"Text"}) <= ($minLen + $minLenAdj) ) {
					my %node;
					$node{"FldId"}=$fldId;
					$node{"RelPos"}=$relPos;
					$node{"RelPosAdj"}=$relPosAdj;
					$node{"Value"}=$_->{"Text"};

					# If the node already exists then push in the array
					# else create a new array with only one element
					if (not exists $masterHash{$_->{"NodeNum"}}) {
						my @nodeArray;
						push @nodeArray, \%node;
						$masterHash{$_->{"NodeNum"}}=\@nodeArray;
						#print "Node does not exist already\n";
					} else {
						$ref=$masterHash{$_->{"NodeNum"}};
						push @$ref, \%node;
						#print "Node exists already\n";
					}
				}
			}
			$i++;		
		}
	}

	# Extract records
	
	# Initialize the values
	$recordNbr=0;
	$fldNbr=1;

	my @nodeArray;
	# Display the hash values in sorted order of node numbers
	foreach $nodeNbr (sort { $a <=> $b } keys %masterHash) {

		$ref=$masterHash{$nodeNbr};
		@nodeArray=@$ref;

		foreach $node (@nodeArray) { 

			# Get the values
			$fldId=$node->{"FldId"};
			$relPos=$node->{"RelPos"};
			$relPosAdj=$node->{"RelPosAdj"};
			$value=$node->{"Value"};

			# Check to see if it is the very first element of the sorted hash
			if ($recordNbr == 0 && $fldNbr == 1) {
				$seperatorTag=$fldId;
			}

			# Check to see the beginning of the next record
			if ($fldId eq $seperatorTag) {
				$firstFldNodeNbr = $nodeNbr;
				$fldNbr=1;
				
				# Check to see if this record has all the mandatory fields
				$hasAllMandatoryFlds=1;
				foreach (@mandatoryFldIds) {
					$hasAllMandatoryFlds=0 if not exists $recHash{$_};	
					last if ($hasAllMandatoryFlds == 0);
				}

				if ($hasAllMandatoryFlds == 1) {

					# Increment the record number counter
					$recordNbr++;

					# Insert the record in the database
					&dbInsertExtractedRecord($dbh, $siteName, \%recHash);

				}

				# Clear the record hash for the next record
				undef %recHash;
			}

			# Store the elements in the record Hash 
			$nodeDiff = $nodeNbr - $firstFldNodeNbr;
			if ($nodeDiff >= $relPos and $nodeDiff <= ($relPos+$relPosAdj) ) {
				$recHash{$fldId}=$value if not exists $recHash{$fldId};
			} 

			# Increment the values
			$fldNbr++;

		}
	}		

	# Insert the last record in the database 
	$firstFldNodeNbr = $nodeNbr;
	$fldNbr=1;
	
	# Check to see if this record has all the mandatory fields
	$hasAllMandatoryFlds=1;
	foreach (@mandatoryFldIds) {
		$hasAllMandatoryFlds=0 if not exists $recHash{$_};	
		last if ($hasAllMandatoryFlds == 0);
	}

	if ($hasAllMandatoryFlds == 1) {

		# Increment the record number counter
		$recordNbr++;

		# Insert the record in the database
		&dbInsertExtractedRecord($dbh, $siteName, \%recHash);

	}

	# Free up the record hash 
	undef %recHash;
}

1;
