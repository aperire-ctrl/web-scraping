use strict;
use Tk;
use Tk::BrowseEntry;
#use English;
#use Carp;
use Mysql;
require 'dbInterface.pl';
require 'HtmlInterface.pl';
require 'ExInterface.pl';

use Tk::Frame;
use Tk::Balloon;
use Tk::DialogBox;
use IO::File;

# Declare global variables here
my $dbh;			# Database Handle
my $dbname="project";		# The database to connect to 
my $user="bindu";		# The user name for the database
my $passwd="bindu";		# The password for the database
my $fileOpened;  		# Global Variable to indicate if the file is open
my %htmlList;			# List holding all the nodes of the HTML page	
my $tree;			# Tree for the HTML page 
my $siteSelected;		# The site that will be learned
my $templateSelected;		# The template chosen to associate with the site 
my @flds;			# The fields of the site
my @fldDepths;			# Depth of each field 
my @fldTags;			# Tag sequence of each field 
my @fldValues;			# Values of each field 
my $fileName;			# Name of the file
my %allListBdryFldIdHash;	# Hash with the boundary fields of the fields in a sub-record of a list of sub-records
				# as the key and value is a reference to an array that contains references
				# to other arrays(list of sub-records). Each such array contains references 
				# to other arrays( sub-records).Each such array containd references to hashes(fields)
my %finalRecsHash;		# Hash with node number as a key and value is reference to an array
				# containing references to hashes. Each hash has a key representing the type of
				# information stored in it. Information stored is a reference to an array
				# containing  either a list, sub-record or a list of sub-records.
my @listSubRecsFldIds_allLists; # Array containing field ids of fields that are part of a  list of sub-record
				# but are not the first field of such a sub-record
my @extractedRecsFldIds;	# Array containing the field id's of the fields extracted to be stored in the database
my @extractedRecsValues;	# Array containing the values of the fields extracted to be stored in the database
my @extractedRecsListIds;	# Array containing the list id's of the fields extracted to be stored in the database
my @extractedRecsParentIds;	# Array containing the field id's of the fields extracted to be stored in the database



# Connecting to the database
#$dbh = DBI->connect("DBI:mysql:$dbname", $user, $passwd) 
$dbh = DBI->connect("DBI:mysql:$dbname", $user, $passwd)
					or die "Can't connect: " . DBI->errstr;

# Initialize the main window and set sizes
my $mainwin = MainWindow->new;
$mainwin->minsize(500,500);
$mainwin->maxsize(800,800);

# Create a Menu Bar
my $menubar = $mainwin->Frame(-relief=>"ridge", -borderwidth=>2);

# Menubuttons appear on the menu bar.
my $filebutton = $menubar->Menubutton(-text=>"File", -underline => 0); # F in File
my $helpbutton = $menubar->Menubutton(-text=>"Help", -underline => 0);  # H in Help

# Menus are children of Menubuttons.
my $filemenu = $filebutton->Menu;
my $helpmenu = $helpbutton->Menu;

# Associate Menubuttons with Menu.
$filebutton->configure(-menu=>$filemenu);
$helpbutton->configure(-menu=>$helpmenu);

# Create menu choices.

# File Menu Choices
$filemenu->command(-label=>"Open", 
				   -underline=>0,
				   -command=>\&openFile); # O in Open
$filemenu->separator;
$filemenu->command(-label=>"Exit", 
				   -underline=>1,
				   -command=>sub {$mainwin->destroy;});  # "x" in Exit

# Help menu choices.
$helpmenu->command(-label=>"About", 
				   -underline => 0,
				   -command=>\&aboutMenu); # A in About

# Pack most Menubuttons from the left.
$filebutton->pack(-side=>"left");

# Help menu should appear on the right.
$helpbutton->pack(-side=>"right");

# Pack the menubar in the window
$menubar->pack(-side=>"top", -fill=>'x', -pady=>5);

# Create buttons and stick them to the frame $frm
my $frm = $mainwin->Frame;
$frm->pack(-side => "right", -fill=>'y', -expand => 'y');

$frm->Button(-text=>"Start Extracting",-width => 15,-command => \&startExtracting)->pack(-padx=>5, -pady=>5);
$frm->Button(-text=>"FineTune",-width => 15,-command => \&fineTune)->pack(-padx=>5, -pady=>5);
$frm->Button(-text=>"Define Template",-width => 15,-command => \&templateCreate)->pack(-padx=>5, -pady=>5);
$frm->Button(-text=>"Associate Template",-width => 15,-command => \&templateAssociate)->pack(-padx=>5, -pady=>5);
$frm->Button(-text=>"Clear Display",-width => 15,-command => \&clearDisplay)->pack(-padx=>5, -pady=>5);
$frm->Button(-text=>"EXIT",-width => 15,-command=>sub{$mainwin->destroy;})->pack(-padx=>5, -pady=>5);

# Status bar widget
my $status = $mainwin->Label(-width=>100,-relief => "sunken", -bd => 1, -anchor => 'w');
$status->pack(-side=>"bottom", -fill=>'y', -padx=>5, -pady=>5);

# Create the text area
my $textArea = $mainwin->Scrolled('Text')->pack;
$textArea->configure(-wrap=>'none');

# Create the learning area
my $extractFrame = $mainwin->Frame->pack;

# Display the Frame for entering values
my $efLbl=$extractFrame->Label(-text =>"Extracting site")->pack;

# Tie the filehandle to the text area
tie (*FILE, 'Tk::Text',$textArea);

print FILE "Extracted records will be displayed here\n";

# Dialogs ...

# Select Site Dialog
my $dlgSiteSel = $mainwin->DialogBox(-title=> "Select the Site",
                                   	-buttons => [ "OK", "Cancel" ],);
my $frmSiteSel = $dlgSiteSel->Frame->pack;
my $beSiteSel = $frmSiteSel->BrowseEntry(-variable=> \$siteSelected,
										   -state=> 'normal' )->pack;
# File Open Dialog
my $dlgOpenFile = $mainwin->DialogBox(-title=> "Extract from File",
	                                  -buttons => [ "OK", "Cancel" ],);
my $frmOpenFile = $dlgOpenFile->Frame;
$frmOpenFile->pack(-side=>"left", -fill=>'y', -expand=>'y', -padx=>5, -pady=>5);
$frmOpenFile->Label(-text=>"File to extract", -width=>15, -padx=>5, -pady=>5)->pack;

my $frmFileTxt = $dlgOpenFile->Frame;
$frmFileTxt->pack(-side=>"left", -fill=>'y', -expand=>'y', -padx=>5, -pady=>5);

my $txtFileName = $frmFileTxt->Entry(-width=>30)->pack(-padx=>5, -pady=>5);
my $btnFileBrowse = $frmOpenFile->Button(-text => "Browse",
									     -command => sub {fileDialog($mainwin, $txtFileName)});
$btnFileBrowse->pack(-side=>"right");

# About Dialog 
my $dlgAboutMenu = $mainwin->DialogBox(-title=> "About Extractor",
	                                  -buttons => [ "OK" ]);
$dlgAboutMenu->Label(-text=>"Extractor Version 1.0")->pack;
$dlgAboutMenu->Label(-text=>"Copyright (C) 2000-2001 Paritosh Rohilla")->pack;

# Template Name & Nbr of Fields Dialog
my $dlgTemplateName = $mainwin->DialogBox(-title=> "Template Details", -buttons=>[ "OK", "Cancel" ]);
my $templateNameFrame=$dlgTemplateName->Frame->pack(-side=>"top", -fill=>'x');
my $nbrFldFrame=$dlgTemplateName->Frame->pack(-side=>"top", -fill=>'x');
$templateNameFrame->Label(-text => "Template Name:")->pack(-side=>"left", -padx=>5, -pady=>5);
my $txtTemplateName = $templateNameFrame->Entry(-width => 25)->pack(-side=>"left", -padx=>5, -pady=>5);
$nbrFldFrame->Label(-text => "# of Fields:")->pack(-side=>"left", -padx=>5, -pady=>5);
my $txtFldNbrFlds = $nbrFldFrame->Entry(-width => 3)->pack(-side=>"left", -pady=>5);

# Template association Fields Dialog
my $dlgTemplateAssocSel = $mainwin->DialogBox(-title=> "Associate template", -buttons=>[ "OK", "Cancel" ]);
my $templateAssocLblFrame=$dlgTemplateAssocSel->Frame->pack(-side=>"top", -fill=>'x');
my $templateAssocSelFrame=$dlgTemplateAssocSel->Frame->pack(-side=>"top", -fill=>'x');
$templateAssocLblFrame->Label(-text => "SITE NAME", -width=>24)->pack(-side=>"left", 
														-padx=>5, -pady=>5);
$templateAssocLblFrame->Label(-text => "TEMPLATE", -width=>24)->pack(-side=>"left", 
														-padx=>5, -pady=>5);
my $beTemplateAssocSiteSel = $templateAssocSelFrame->BrowseEntry(-variable=> 
	\$siteSelected, -state=> 'normal' )->pack(-side=>"left", -padx=>5, -pady=>5);
my $beTemplateAssocTemplateSel = $templateAssocSelFrame->BrowseEntry(-variable=> 
	\$templateSelected, -state=> 'normal' )->pack(-side=>"left", -padx=>5, -pady=>5);

# Dialogs End ...

MainLoop;

#Routine invoked when the button "Start Extracting" is clicked
sub startExtracting {

my $button;
my $done = 0;
my $i;
my @depth;
my @tagSeq;
my $fldId;
my $nodeNbr;
my $fldName;
my $prevFldName;
my $fldText;
my $name;
my $type;
my $levelId;
my $mandatoryFlg;
my $listSubRecBdryFldId;
my $listSubRecRelPos;
my $listSubRecRelPosAdj;
my @mandatoryFldIds;
my $hasAllMandatoryFlds;
my $depth;
my $tagSeq;
my $keywords;
my $omitwords;
my @sites;
my @fldIds;
my $fldDef;
my @nodes;
my %masterHash;
my $seperatorTag;
my $relPos;
my $bdryFldId;
my $minLen;
my $depthAdj;
my $relPosAdj;
my $minLenAdj;
my $listId;
my $fanout;
my $treeLevel;
my $fanoutAdj;
my $beginsWith;
my $endsWith;
my $preceededBy;
my $followedBy;
my $nodeDiff;
my $recordNbr;
my $fldNbr;
my $firstFldNodeNbr;	# Node number of the first field of the record
my $node;
my $ref;
my @parentIds;
my $childNamesRef;
my $childName;
my $pId;
my $fName;
my %tempRecsHash;
my $m;
my %allLists;
	
	print("\nExtraction process began");
	# Select the site 
	do {
	
		# Display appropriate message on the status bar
		$status->configure(-text=> "Site Selection...");

		# Show the dialog
		@sites = &dbGetSites($dbh);
		$beSiteSel->configure(-choices=>\@sites);
		$button = $dlgSiteSel->Show;
		if ($button eq "OK")
		{
			if (defined($siteSelected) && length($siteSelected)) 
			{
				print "$siteSelected Selected\n";
				$done = 1;
			} 
			else
			{
				print "You didn't select a Site!\n";
			}
		}
		else 
		{
			print "Cancelled out.\n";
			$done = 1;

			# Display appropriate message on the status bar
			$status->configure(-text=> "");

			return;
		}
	} until $done;

	# Display appropriate message on the status bar
	$status->configure(-text=> "Extracting records...");

	# Display the Frame for entering values
	$efLbl->configure(-text=> "Extracting site $siteSelected");


	# Main code to extract records

#*********Extraction of nodes for all the fields  irrespective of the sub-record or list they belong to****************

	print("\n Extracting nodes for all the fields of the record");
	# Get the ids of the fields that are not sub-records for this site
	# ordered by their field sequences
	@fldIds = &dbGetFldIdsWithValues($dbh, $siteSelected);

	# Extract data from the tree for each field 
	foreach (@fldIds)
	{

		# Get the field definition from the FINALVALUES table  
		$fldDef = &dbGetFldDef($dbh, $siteSelected, $_);

		for $m(0..$#{$fldDef})
		{
			# Get the field definitions
			$fldId = $fldDef->[$m][0];   		 #$fldDef->{"FLDID"};
			$name = $fldDef->[$m][1];	 	 #$fldDef->{"FLDNAME"};
			$type = $fldDef->[$m][2];		 #$fldDef->{"FLDTYPE"};
			$levelId = $fldDef->[$m][3]; 		 #$fldDef->{"LEVELID"};
			$depth = $fldDef->[$m][4];   		 #$fldDef->{"DEPTH"};
			$tagSeq = $fldDef->[$m][5];  		 #$fldDef->{"TAGSEQ"};
			$relPos = $fldDef->[$m][6];  		 #$fldDef->{"RELPOS"};
			$bdryFldId = $fldDef->[$m][7];		 #$fldDef->{"RECBDRYFLDID"};
			$minLen = $fldDef->[$m][8];		 #$fldDef->{"MINLEN"};
			$keywords = $fldDef->[$m][9];		 #$fldDef->{"KEYWORDS"};
			$omitwords = $fldDef->[$m][10];		 #$fldDef->{"OMITWORDS"};
			$relPosAdj = $fldDef->[$m][11];		 #$fldDef->{"RELPOSADJ"};
			$minLenAdj = $fldDef->[$m][12];		 #$fldDef->{"MINLENADJ"};
			$listId =  $fldDef->[$m][13];		 #$fldDef->{"LISTID"};
			$listSubRecBdryFldId = $fldDef->[$m][14];#$fldDef->{"LISTSUBRECBDRYFLDID"};
			$listSubRecRelPos = $fldDef->[$m][15];	 #$fldDef->{"LISTSUBRECRELPOS"};
			$listSubRecRelPosAdj = $fldDef->[$m][16];#$fldDef->{"LISTSUBRECRELPOSADJ"};
			$fanout = $fldDef->[$m][17];		 #$fldDef->{"FANOUT"};
			$treeLevel = $fldDef->[$m][18];		 #$fldDef->{"LEVEL"};
			$fanoutAdj = $fldDef->[$m][19];		 #$fldDef->{"FANOUTADJ"};
			$beginsWith = $fldDef->[$m][20];	 #$fldDef->{"BEGINSWITH"};
			$endsWith = $fldDef->[$m][21];		 #$fldDef->{"ENDSWITH"};
			$preceededBy = $fldDef->[$m][22];	 #$fldDef->{"PRECEEDEDBY"};
			$followedBy = $fldDef->[$m][23];	 #$fldDef->{"FOLLOWEDBY"};
			
			

			# Get the depth and tagseq values
			@depth = split /;/, $depth;
			@tagSeq = split /:/, $tagSeq;

			$i = 0;
			

			# get all those nodes from the tree, satisfying the conditions
			#@nodes = &identifyNode($tree, $depth[$i], $tagSeq[$i], $type, $keywords, $omitwords, $fanout, $treeLevel, $fanoutAdj);
			@nodes = &identifyNode($tree, \@depth, \@tagSeq, $type, $keywords, $omitwords, $fanout, $treeLevel, $fanoutAdj, $beginsWith, $endsWith, $preceededBy, $followedBy);

			print("\n Nodes extracted for $name:");
			# Put the nodes in the master hash
			foreach (@nodes) 
			{
				#create a hash representing the field definition for each extracted node
			
			 	my %node;
				$node{"FldId"} = $fldId;
				$node{"FldName"} = $name;
				$node{"FldType"} = $type;
				$node{"LevelId"} = $levelId;
				$node{"RelPos"} = $relPos;
				$node{"RelPosAdj"} = $relPosAdj;
				$node{"Selected"} = 'N';
				$node{"bdryFldId"} = $bdryFldId;
				$node{"Text"} = $_->{"Text"};
				$node{"NodeNbr"} = $_->{"NodeNum"};
				$node{"ListId"} = $listId;
				$node{"ListSubRecBdryFldId"} = $listSubRecBdryFldId;
				$node{"ListSubRecRelPos"} = $listSubRecRelPos;
				$node{"ListSubRecRelPosAdj"} = $listSubRecRelPosAdj;
					

				print("\n");
				print("Text:  ");
				print($node{"Text"});
				print("	   Node Nbr:  ");
				print($node{"NodeNbr"});
				
				# create a hash with the field name as the key
				# and the value is a reference to an array containing all
				# the nodes(reference to the hashes) extracted for that field
				if (not exists $masterHash{$name}) 
				{
					my @nodeArray;
					push @nodeArray, \%node;
					$masterHash{$name} = \@nodeArray;
				} 
				else
				{
					$ref = $masterHash{$name};
					push @$ref, \%node;
				}
				
			}#foreach (@nodes) 

			$i++;		
		}#for $m
	}#foreach (@fldIds)

	#*******Formation of records- Bottom Up Approach*****************************
	
	print("\n Forming records");
	
	#get unique parent ids of the fields, ordered in reverse order of their level ids
	@parentIds = &dbGetParentIds($dbh, $siteSelected);
	push(@parentIds, 0);
	
		
	my $fName;
	my %subRecHash;
	my %listHash;
	my @nodeArray;
	my $subRecNode;
	my $subRecHashRef;
	my $listHashRef;
	my @subRecNodeArray;
	my @listNodeArray;
	my $ndNum;
	my %node;
	my @tempRecsArray;
	my @tempListArray;
	my %tempFldIdListHash;
	my $recNo;
	my $nodeNmbrToCmp;
	my $found;
	my $fieldID;
	my $recs;
	my $first;
	my $list_Flg;
	
	
	$recordNbr = 0;
	foreach $pId (@parentIds)
	{
		print("\n Current Parent Id: $pId");
		$first = 1;
		
		# get the definition of al the children of this parent
	    	$childNamesRef = &dbGetChildNames($dbh, $siteSelected, $pId);
		
		print("\n Children details:");
		
		# Initialize the values
		$fldNbr=1;
		$recNo = 0;
		undef @tempRecsArray;
		undef @tempListArray;
		undef %tempFldIdListHash;
		undef $recs;
		undef %subRecHash;
		undef @mandatoryFldIds;
		undef %listHash;
		
		# get the mandataory field ids of the mandatory fields of this sub-record
		for $i ( 0 .. $#{$childNamesRef} )
		{
			print("\n Name: ");
			print($childNamesRef->[$i][1]);
			print("\n Mandatory Flg: ");
			print($childNamesRef->[$i][3]);
			print("\n SubRecord Flg: ");
			print($childNamesRef->[$i][2]);
			print("\n List Flg: ");
			print($childNamesRef->[$i][4]);
			
			if($childNamesRef->[$i][3] == 'Y')
			{
				push( @mandatoryFldIds, $childNamesRef->[$i][0] );
			}
			
		  	$childName = $childNamesRef->[$i][1]; 
		  	$list_Flg = $childNamesRef->[$i][4];
		  
		  	# separate the contents of the master hash into two separate hashes
		  	# one for the fields that are lists and one for the other fields
		        foreach $fName ( keys %masterHash ) 
		  	{
		  		$ref = $masterHash{$fName};
		  		@nodeArray = @$ref;
				if( $fName eq $childName )
				{
					foreach $node (@nodeArray)
					{
						$ndNum = $node->{"NodeNbr"};
						# for the field which is a list, create a hash with the node number
						# as the key and the value is a reference to an array containing nodes 
						# that share the same node number
						if( $list_Flg eq 'Y' )
						{
							if (not exists $listHash{$ndNum}) 
							{
								my @listNodeArray;
								push @listNodeArray, $node;
								$listHash{$ndNum} = \@listNodeArray;
							} 
							else
							{
								$listHashRef = $listHash{$ndNum};
								push @$listHashRef, $node;
							}

						}
						# for the field which is not a list, create a hash with the node number
						# as the key and the value is a reference to an array containing nodes 
						# that share the same node number
						if ( $list_Flg eq 'N' )
						{
							if (not exists $subRecHash{$ndNum}) 
							{
								my @subRecNodeArray;
								push @subRecNodeArray, $node;
								$subRecHash{$ndNum} = \@subRecNodeArray;
							} 
							else
							{
								$subRecHashRef = $subRecHash{$ndNum};
								push @$subRecHashRef, $node;
							}
						}#end else #if ( $list_Flg != 'Y' )
					}#end foreach $node						
				}#end if
		      }#end foreach fName
		}#end for $i
					
		my $newRecord;
		my @fids;
		my @sorted_fids;
		my $hash_ref;
		my @sorted_subRecNodeArray;
		my $listNode;
		my $list_Id;
		my $list_nodeNbr;
		my $list_relPos;
		my $list_relPosAdj;
		my $listNo = 0;
		my $list_bdryFldId;
		my @listArray;
		my $recs;
		my $list_nodeDiff;
		my $list_nodeNmbrToCmp;
		my $list_fldId;
		my %fldIdListHash;
		my $listArrayRef;
		my $fldIdList;
		my $fldId_key;
		my $listArray;
		my $tempListArrayRef;
		my $t;
		
		
	#*****************************Formation of Simple Lists**********************************
		
		# for the list hash  sorted on the node number, create another hash with the field id as the key
		# and the value is a reference to an array containing nodes 
		# that share the same node number
				
		print ("\n Forming simple lists:");
		foreach $ndNum ( sort { $a <=> $b } keys %listHash ) 
		{
		
			$listHashRef = $listHash{$ndNum};
			@listNodeArray = @$listHashRef;

			foreach $listNode (@listNodeArray)
			{
				$list_fldId = $listNode->{"FldId"};
				if (not exists $fldIdListHash{$list_fldId}) 
				{
					my @listArray;
					push @listArray, $listNode;
					$fldIdListHash{$list_fldId} = \@listArray;
				} 
				else
				{
					$listArrayRef = $fldIdListHash{$list_fldId};
					push @$listArrayRef, $listNode;
				}
				undef $listArrayRef;
								
			}#end foreach $listNode (@listNodeArray)				
			
		}
					
		foreach $fldIdList ( keys %fldIdListHash ) 
		{
			$listHashRef = $fldIdListHash{$fldIdList};
			@listNodeArray = @$listHashRef;
			
			foreach $listNode (@listNodeArray)
			{ 
				
				my @listArray;
				$list_fldId = $listNode->{"FldId"};
				$list_Id = $listNode->{"ListId"};
				$list_nodeNbr = $listNode->{"NodeNbr"};
				$list_relPos = $listNode->{"RelPos"};
				$list_relPosAdj = $listNode->{"RelPosAdj"};

				# if the node has list id = 1, create a hash with field id of the list field
				# as the key and the value is a reference to an array containing refences to other arrays
				# each such other array contains a reference to a hash, representing the list node.
				if ($list_Id == 1)
				{
					print ("\n Creating a new list");
					$list_relPos = 0;
					$list_bdryFldId = $list_fldId;

					if ( not exists $tempFldIdListHash{$list_fldId} )
					{
						my @list_Array;
						my @tempListArray;
						push @list_Array, $listNode;
						push @tempListArray, \@list_Array;
						$tempFldIdListHash{$list_fldId} = \@tempListArray;
					}
					else
					{
						my @list_Array;
						my @tempListArray;
						push @list_Array, $listNode;
						$tempListArrayRef = $tempFldIdListHash{$list_fldId};
						@tempListArray = @$tempListArrayRef;
						push @tempListArray, \@list_Array;
						$tempFldIdListHash{$list_fldId} = \@tempListArray;
					
					}
					$listNo++;
				}#if ($list_Id == 1)
				else
				{
					my $list_node;
					my @tempListArray;
					my $totLists;
					my @listRefArray;
					my $tempFldIdListHashRef;
					
					# if the node has a list id other than 1, retreive the saved contents of the hash
					$tempFldIdListHashRef = $tempFldIdListHash{$list_fldId};
					if ($tempFldIdListHashRef)
					{
						@tempListArray = @$tempFldIdListHashRef;
						$totLists = $#tempListArray;
						
						# compare the node's node number with the last list item in each 
						# previously formed list, saved in the hash
						foreach $t (0..$totLists )
						{
						  my $tempListArrayRef;
						  my @tempNodesArray;

							$tempListArrayRef = $tempListArray[$t];
							@tempNodesArray = @$tempListArrayRef;
							$list_node = pop @tempNodesArray;
							$list_nodeNmbrToCmp = $list_node->{"NodeNbr"};
							$list_nodeDiff = $list_nodeNbr - $list_nodeNmbrToCmp;
							
							# if the relative position condition is satisfied, push the node into the list
							# containing the list item, with which the current node's node number was compared
							if ($list_nodeDiff >= $list_relPos and $list_nodeDiff <= ($list_relPos + $list_relPosAdj) )
							{
							    my $list_copy;
								push (@tempNodesArray, $list_node);
								$list_copy = &copyList($listNode);
								push (@tempNodesArray, $list_copy);
								$tempListArray[$t] = \@tempNodesArray;
								
								print("\nRelative position satisfied");
								print ("\nAdded list item to an existing list:");
							}
							else
							{
								print("\nRelative position not satisfied")
							}

							push ( @listRefArray, $tempListArray[$t] );
						  }#end foreach $t

						# save the updated list
						$tempFldIdListHash{$list_fldId} = \@listRefArray;
					}#end if
				}#end else 							
				
			}#foreach $listNode (@listNodeArray)
		}#foreach $fldIdList ( keys %fldIdListHash ) 
		
			
		my $list;
		my $listItem;
		$listNo = 0;
				
		# create a hash with the field of the list field as the key
		# and value is a refence to an array containing references to other arrays
		# each such other array contains references to hashes, representing list items
		
		print("\n Simple lists Formed:");
		foreach $fldId_key (keys %tempFldIdListHash)
		{
		   my @arrayRefList;
			
			$listArrayRef = $tempFldIdListHash{$fldId_key};
			@arrayRefList = @$listArrayRef;
			$allLists{$fldId_key} = \@arrayRefList;
		
			print ("\n\nlistNo: $listNo \n");
			
			foreach $listArrayRef (@arrayRefList)
			{
				$listNo++;
				@listArray = @$listArrayRef;			
				$listItem = 0;
				
				print("\n List No:$listNo");
				foreach $list (@listArray)
				{
				    $listItem++;
					print("\n\nlistItem: $listItem \n");
					print("\n");
					print($list->{"FldName"});
					print(" ");
					print($list->{"Text"});
					print("  ListId:");
					print($list->{"ListId"});
				}
			}
		}
		
	#*****************************Formation of Sub-Records**********************************
						
	# for the sub-record hash  sorted on the node number, create another hash with the field id as the key
	# and the value is a reference to an array containing nodes 
	# that share the same node number
	
	print("\n Forming sub-records");
	foreach $ndNum ( sort { $a <=> $b }keys %subRecHash ) 
	{
		undef @fids;
		undef @sorted_fids;
		undef @sorted_subRecNodeArray;
			
		$subRecHashRef = $subRecHash{$ndNum};
		@subRecNodeArray = @$subRecHashRef;
				
		# sort the contents of the array on the fieldId of the Hash references
		foreach(@subRecNodeArray)
		{ 
			push @fids, $_->{"FldId"};
		} 

		@sorted_fids = sort { $a<=> $b } (@fids); 
		foreach $hash_ref (@sorted_fids) 
		{ 
		   foreach (@subRecNodeArray)
		   {
				if($hash_ref == $_->{"FldId"})
				{
					push @sorted_subRecNodeArray, $_; 
			    		next; 
			 	} 
		   } 
		} 

		LOOP:foreach $subRecNode (@sorted_subRecNodeArray)
		{ 
			$newRecord = 0;
			# Get the values
			$fldId = $subRecNode->{"FldId"};
			$nodeNbr = $subRecNode->{"NodeNbr"};
			$fldText = $subRecNode->{"Text"};
			$fldName = $subRecNode->{"FldName"};
			$relPos = $subRecNode->{"RelPos"};
			$relPosAdj = $subRecNode->{"RelPosAdj"};
			$bdryFldId = $subRecNode->{"bdryFldId"};

			# get the boundary field of each sub-record
			if($first == 1)
			{
				# if the field is same as the first field defined in the sub-record
				# mark that field as the boundary field of each sub-record
				if( ($childNamesRef->[0][0]) == $fldId )
				{
					$seperatorTag = $fldName;
					$first = 0;	 
				}
				else
				{
				  next LOOP;
				}

			}
												
			my @nodesArray;

			# If the field is the boundary field create an array containing the reference to the node
			# save the reference to this array in another array
			if ($fldName eq $seperatorTag)
			{
				$newRecord = 1;
				$fldNbr = 1;
				$relPos = 0;
				
				# save the field id of this boundary field
				$bdryFldId = $fldId;

				push @nodesArray, $subRecNode;
				push @tempRecsArray, \@nodesArray;
				
				print("\n New sub-record created ");
				$recNo++;
			}#if ($fldName eq $seperatorTag)

			my $nodesArrayRef;
			my $node;

			$found = 0;
			
				
			#Mapping the node with each node in each record of tempRecsArray
			my @tempNodesArray;
			LOOP1:foreach $recs (@tempRecsArray)
			{
				my $nodeFldId;
				my $contains;

				# search for the field's boundary field, in the list of previously saved sub-records
				@tempNodesArray = @$recs;
				foreach $node (@tempNodesArray)
				{
					$nodeFldId = $node->{"FldId"};
					if ( $nodeFldId == $bdryFldId )
					{
						$found = 1;
						
						#get the node number of the boundary field
						$nodeNmbrToCmp = $node->{"NodeNbr"};

						# calculate the node difference
						$nodeDiff = $nodeNbr - $nodeNmbrToCmp;
						
						# if the condition is satisfied, add the node to the sub-record that contains the boundary field
						if ($nodeDiff >= $relPos and $nodeDiff <= ($relPos + $relPosAdj) )
						{
							$contains = 0;
							foreach(@$recs)
							{
								if ( $_ eq $subRecNode )
								{
									$contains = 1;
								}
								last if ($contains == 1);
							}

							if( ($newRecord == 0) and ($contains == 0) )
							{
								push @$recs, $subRecNode;
								print("\n Relative position satisfied ");
								print("\n Added field to an existing sub-record ");
							}
										
							$fldNbr++;
						 }
						else
						{
							print("\nRelative Position not satisfied")
						}
					}#if( $node->{fldId} == $bdryFldId )
				}#foreach $node (@tempNodesArray)
			    }#end LOOP1	
						
			}#end LOOP foreach $subRecNode (@sorted_subRecNodeArray)
				
		}#foreach $ndNum ( sort { $a <=> $b }keys %subRecHash ) 
			
			foreach $recs ( @tempRecsArray )
			{
				my @nodesArray;
				@nodesArray = @$recs;

				$recordNbr++;
				my $recsArrayRef;
							
				# create a hash with the field id of the first field in a sub-record as the key
				# and value is a reference to an array containing refences to other arrays. Each such
				# other array contains references to hashes, representing fields of the sub-record
				if( not exists $tempRecsHash{$nodesArray[0]->{"FldId"} } )
				{
					my @recsArray;
					my $nodeArrayRef = \@nodesArray;
					push (@recsArray, $nodeArrayRef);
					$tempRecsHash{$nodesArray[0]->{"FldId"}} = \@recsArray;

				}
				else
				{
					$recsArrayRef = $tempRecsHash{$nodesArray[0]->{"FldId"} };
					my $nodesArrayRef = \@nodesArray;
					push( @$recsArrayRef, $nodesArrayRef );
				}
				
			 }#end foreach $recs ( @tempRecsHash )
	
			 print("\n Sub Records Formed:");
			 my $key;
			 my $index;
			 my $recsArrayRef;
			 my @recArray;
			 
			 	foreach $key (sort { $a <=> $b }keys %tempRecsHash  )
			 	{
			 	   	$recsArrayRef = $tempRecsHash{$key};
			 		@recArray = @$recsArrayRef;
			 		foreach $index (@recArray)
			 		{
			 			print("\n Sub Record:");
			 			foreach(@$index)
			 			{
			 				print("\n");
			 				print("Name: ");
			 				print($_->{"FldName"});
			 				print("Text: ");
			 				print($_->{"Text"}); 
			 			}
			 			print("\n");
			 		}
			 		print("\n\n");
				}
	
			
				
			 # Make a document from a file 
			 open (DOCFILE, $fileName) || die "Failed to open $fileName\n";
								
			 # Call the function to put the record in the database
			 #&extractRecords($dbh, $siteSelected, $fileName);
		
			}#foreach $pId
		
			
	my $fldIdArrayRef;
	my $bdryFldIdArrayRef;
	my @fldIdArray;
	my @bdryFldIdArray;
	my $fldIdArrayRefs;
	my $bdryFldIdArrayRefs;
	my @fldIdList;
	my @bdryFldIdList;
	my $fldIdListItem;
	my $bdryFldIdListItem;
	my $fldIdNodeNbr;
	my $fldIdlistSubRecRelPos;
	my $fldIdlistSubRecRelPosAdj;
	my $bdryFldNodeNbrToCmp;
	my $listSubRecNodeDiff;
	my $bdryFldidsRef;
	my $i;	
	my $listFldId;
	my $listBdryFldId;
	my $bdryFldIdsHashRef;
	my %bdryFldIdsHash;
	my $bdryFldId;
	my $allListBdryFldIdHashRef;
		
	#**********************Formation of list of subrecords*******************************
	
	print("\nForming list of sub-records");	
	
	# get the field id's and their list of sub-records boundary field id's(LSBD) for those fields
	# that do have their LSBD as 0 or itself.
	$bdryFldidsRef = &dbGetListSubRecBdryFldIds($dbh, $siteSelected);
	
	# group the field ids and their LSBD's into different groups-one for each LSBD
	$bdryFldIdsHashRef = &groupByBdryFldId($bdryFldidsRef);
	%bdryFldIdsHash = %$bdryFldIdsHashRef;
				
	foreach $bdryFldId (keys %bdryFldIdsHash )
	{
	   my $fldIdsArrayRef;
	   my @fldIdsArray;
	   my $bdryFldIdRef;
	   my @allListSubRecs;

	 	$fldIdsArrayRef = $bdryFldIdsHash{$bdryFldId};
	 	@fldIdsArray = @$fldIdsArrayRef;

		foreach $bdryFldIdRef (@fldIdsArray )
		{
		   my @array;
		   @array = @$bdryFldIdRef;

		    
  		  	# get the field id and its LSBD
		 	$listFldId = $array[0];
			$listBdryFldId = $array[1];
			
			# save the field ids of these fields
			push(@listSubRecsFldIds_allLists, $listFldId);

			# get the all the lists for the field and its boundary field
			# from the previously saved hash
			$fldIdArrayRef = $allLists{$listFldId};
			$bdryFldIdArrayRef = $allLists{$listBdryFldId};

			if(defined $fldIdArrayRef)
			{
				@fldIdArray = @$fldIdArrayRef;
				@bdryFldIdArray = @$bdryFldIdArrayRef;
			}

			LOOP2:foreach $fldIdArrayRefs ( @fldIdArray )
			 {
			  	@fldIdList = @$fldIdArrayRefs;
			    	foreach $bdryFldIdArrayRefs ( @bdryFldIdArray )
			    	{
					my @listSubRecs;

					@bdryFldIdList = @$bdryFldIdArrayRefs;
					LOOP3:foreach $fldIdListItem ( @fldIdList )
					{
						# get the details of the list item
						$fldIdNodeNbr = $fldIdListItem->{"NodeNbr"};
						$fldIdlistSubRecRelPos = $fldIdListItem->{"ListSubRecRelPos"};
						$fldIdlistSubRecRelPosAdj = $fldIdListItem->{"ListSubRecRelPosAdj"};

						LOOP1:foreach $bdryFldIdListItem ( @bdryFldIdList )
						 {
						 	# get the node number of the boundary field (list item)
							$bdryFldNodeNbrToCmp = $bdryFldIdListItem->{"NodeNbr"};
							if ( $fldIdNodeNbr < $bdryFldNodeNbrToCmp )
							{
								last LOOP1;
							}
							else
							{
								# calculate the node difference
								$listSubRecNodeDiff = $fldIdNodeNbr - $bdryFldNodeNbrToCmp;
								
								#if the condition is satisfied create list of sub-records
								if ($listSubRecNodeDiff >= $fldIdlistSubRecRelPos and $listSubRecNodeDiff <= ($fldIdlistSubRecRelPos + $fldIdlistSubRecRelPosAdj) )
								{
								   my $listSubRecRefs;
								   
								   	print("\n Relative Position satisfied");
									$listSubRecRefs = addSubrecfields($fldIdListItem, $bdryFldIdListItem, \@listSubRecs, \@allListSubRecs );
									@listSubRecs = @$listSubRecRefs;
									next LOOP3;
								}

							 }

				  	    	 }#end LOOP1 foreach $bdryFldIdListItem
					}#end LOOP3 foreach $fldIdListItem

					# save the reference to the array containing the list of sub-records in another array
					if ( ($#listSubRecs + 1 ) > 0 )
					{
						push @allListSubRecs, \@listSubRecs;
					}
			    	}#end foreach $bdryFldIdArrayRefs
			   }#end foreach $fldIdArrayRefs
			}#end foreach $bdryFldIdRef
			
			# save the reference to the array containing the lists of sub-records in a hash
			# with LSBD as the key
			$allListBdryFldIdHash{$bdryFldId} = \@allListSubRecs;
			
			# add back all those LSBD list items that do not appear in the lists of sub-records
			$allListBdryFldIdHashRef = &addUnmappedBdryLists(\%allLists, \%allListBdryFldIdHash, $bdryFldId);
			%allListBdryFldIdHash = %$allListBdryFldIdHashRef;
			
			
			my $i;
			my $j;
			my $k;
			my @array1;
			my @array2;

				print("\nList of SubREcords Formed:");
				foreach $bdryFldId ( keys %allListBdryFldIdHash )
				{
					my $allListSubRecsRef = $allListBdryFldIdHash{$bdryFldId};
					my @allListSubRecs = @$allListSubRecsRef;
					foreach $i (@allListSubRecs )
					{
						print("\n New List");
						@array1 = @$i;
						foreach $j(@array1)
						{
							print("\nSubRecord\n");
							@array2 = @$j;
							foreach $k (@array2)
							{
								print("FldName:");
								print($k->{"FldName"});
								print("   FldText:");
								print($k->{"Text"});
								print("   ListId:");
								print($k->{"ListId"});
								print("   RelPos:");
								print($k->{"RelPos"});
								print("\n");
							}
						}
					}
				}
						
		}#end foreach $bdryFldId
		
		
     #****************************Final Record Formation********************************************
     		# form complete records from the three hashes created for the sub-records, lists
     		# and list of sub-records
		&formCompleteRecords(\%tempRecsHash, \%allLists, \%allListBdryFldIdHash); 
		
		# perform the mandatory field check, print the final records in the display area and
		# put the extracted records in the database
		&mandatoryFldCheckandPrintFinalRecsHash();
		
		
		#undefine hashes, array
		undef %allListBdryFldIdHash;
		undef %tempRecsHash;
		undef %allLists;
		undef %finalRecsHash;
		undef @listSubRecsFldIds_allLists;
		
				
		# Display appropriate message on the status bar
		$status->configure(-text=> "Done...");
}#end sub startExtracting
	
	
# Routine to copy a hash
sub copyList{
	my ($node) = @_;
	my $node_copy;
	
		$node_copy->{"FldId"} = $node->{"FldId"};
		$node_copy->{"FldName"} = $node->{"FldName"};
		$node_copy->{"FldType"} = $node->{"FldType"};
		$node_copy->{"LevelId"} = $node->{"LevelId"};
		$node_copy->{"RelPos"} = $node->{"RelPos"};
		$node_copy->{"RelPosAdj"} = $node->{"RelPosAdj"};
		$node_copy->{"Selected"} = $node->{"Selected"};
		$node_copy->{"bdryFldId"} = $node->{"bdryFldId"};
		$node_copy->{"Text"} = $node->{"Text"};
		$node_copy->{"NodeNbr"} = $node->{"NodeNbr"};
		$node_copy->{"ListId"} = $node->{"ListId"};
		$node_copy->{"ListSubRecBdryFldId"} = $node->{"ListSubRecBdryFldId"};
		$node_copy->{"ListSubRecRelPos"} = $node->{"ListSubRecRelPos"};
		$node_copy->{"ListSubRecRelPosAdj"} = $node->{"ListSubRecRelPosAdj"};

	return $node_copy;
}

# Routine to create a list of subrecords
sub addSubrecfields{
my ($fldIdListItem, $bdryFldIdListItem, $listSubRecsRef, $allListSubRecsRef) = @_;
my @listSubRecs = @$listSubRecsRef;
my @allListSubRecs = @$allListSubRecsRef;
my $found = 0;
my $list;
my @listsOfSubRecs;
my $listOfSubRecsRef;
my @listOfSubRec;
my $subRecRef;
my $fldNameFound;
my $fldName;


	
	if ( ($#listSubRecs + 1) == 0 )
	{
		# do not add the list item, if the LSBD list item has a list id != 1
		if ($bdryFldIdListItem->{"ListId"} != 1 )
		{
			$listSubRecsRef = \@listSubRecs;
			return ($listSubRecsRef);
				
		}
	}

	foreach $list(@allListSubRecs)
	{
		@listsOfSubRecs = @$list;
		foreach $listOfSubRecsRef (@listsOfSubRecs )
		{
			@listOfSubRec = @$listOfSubRecsRef;
			foreach $subRecRef (@listOfSubRec )
			{
				# if the LSBD list item already exists in a list of sub-records
				if ( $subRecRef->{"NodeNbr"} == $bdryFldIdListItem->{"NodeNbr"} )
				{
					print("A list of sub-records with the boundary field already exists");
					
					$fldName = $fldIdListItem->{"FldName"};					
					
					# if the list item does not already belong to this list of sub-records
					$fldNameFound = fldNameExists($fldName, @listOfSubRec);
					if (!$fldNameFound)
					{
						print("\n Adding list item to an existing list of sub-records");
						
						# add the list item to this list of sub-records
						push (@$listOfSubRecsRef, $fldIdListItem);
						$found = 1;
						last;
					}
				}#end if
			}#end foreach $subRecRef
		}#end foreach $listsOfSubRecsRef
	}#foreach $list
	
	# create a new sub-record with the LSBD list item and the list item
	# and add the new sub-record to the list provided
	if (!$found)
	{
		my @subRec;
		push @subRec, $bdryFldIdListItem;
		push @subRec, $fldIdListItem;
		push @listSubRecs, \@subRec;
		print ("\n Created a new list of sub-records");
	}#end if
	
	# return the updated list of sub-records
	$listSubRecsRef = \@listSubRecs;
	return ($listSubRecsRef);
}#end addSubrecfields


#subroutine to group fldids and bdryfldids into different groups-one for each bdryfldid
sub groupByBdryFldId{
my ($bdryFldidsRef) = @_;
my %bdryFldIdHash;
my $i;
     	   	
   	foreach $i(0..$#{$bdryFldidsRef} )
   	{
   		if ( not exists $bdryFldIdHash{$bdryFldidsRef->[$i][1]} )
   		{
   		   my @fldidsArray;
   		   	
   		   	push ( @fldidsArray, $bdryFldidsRef->[$i] );
   			$bdryFldIdHash{$bdryFldidsRef->[$i][1]} = \@fldidsArray;
   		}
   		else
   		{
   		    my $fldIdsArrayRef = $bdryFldIdHash{$bdryFldidsRef->[$i][1]};
   		    push ( @$fldIdsArrayRef, $bdryFldidsRef->[$i] );
   		}
   		
   	}#end foreach $i
   	
   	return \%bdryFldIdHash;
   	
}#end sub groupByBdryFldId


# Routine to check if a "fldname" argument already exists in a sub-record of a list of sub-records
sub fldNameExists{
my ($fldName, @listOfSubRec) = @_;
my $subRecRef;
my $found = 0;
	
		foreach $subRecRef (@listOfSubRec )
   		{
   			if ( $subRecRef->{"FldName"} eq $fldName )
   			{
   				$found = 1;
   				last;
   			}#end if
		}#end foreach $subRecRef
   	return $found;
}#end sub textExists


# Routine to form final complete records from subrecords, lists and list and subrecords
sub formCompleteRecords {
 my ($tempRecsHashRef, $allListsRef, $allListBdryFldIdHashRef) = @_;
 my %tempRecsHash = %$tempRecsHashRef;
 my %allLists = %$allListsRef;
 my  %allListBdryFldIdHash = %$allListBdryFldIdHashRef;
 my $bdryFldId;
 my $i;
 my @array1;
 my $j;
 my @array2;
 my $relPos;
 my $nodeNbr;
 my $relPosAdj;
 my $k;
 my $array1Ref;
 my @array3;
 my $l;
 my @array4;
 my $m;
 my @bdryFldIds;
 my @listSubRecsBdryFldIds;
 my @listBdryFldIds;
 my @subRecsBdryFldIds;
 my $fldIdHashRef;
 my %fldIdHash;
 my @levelIds;
 my $levelId;
 my $fldId;
 my @fldIds;
 my $arrayRef;
 my @array;
 my $index;
 my $hashKey;
 my $fldId_value;
 my @fldIdsArray;
 my $formCmpRecs = 0;

	print("\n Forming Complete Records");
	# get the keys of all the three hashes	
 	@subRecsBdryFldIds = keys %tempRecsHash;
 	@listBdryFldIds = keys %allLists;
 	@listSubRecsBdryFldIds = keys %allListBdryFldIdHash;
 	
 	my $numSubRecsBdryFldIds = $#subRecsBdryFldIds + 1;
 	my $numListBdryFldIds = $#listBdryFldIds + 1;
 	my $numListSubRecsBdryFldIds = $#listSubRecsBdryFldIds + 1;
 	 
 	# if only one of the three hashes is non-empty with the other two hashes being empty
 	# convert the non-emtpty hash into the hash that contains the final records. All the
 	# final records have the same format irrespective of their contents
 	if ($numSubRecsBdryFldIds && !$numListBdryFldIds && !$numListSubRecsBdryFldIds)
 	 {
 	   if ( $numSubRecsBdryFldIds == 1)
 	   {
 	      &formFinalRecords(\%tempRecsHash, "SUBREC");
 	      $formCmpRecs = 1;
 	   }  
 	 }
 	 if (!$numSubRecsBdryFldIds && $numListBdryFldIds && !$numListSubRecsBdryFldIds)
	 {
	      if ( $numListBdryFldIds == 1)
	      {
	      	&formFinalRecords(\%allLists, "LIST");
	      	$formCmpRecs = 1;
	      }
 	 }
 	 if (!$numSubRecsBdryFldIds && !$numListBdryFldIds && $numListSubRecsBdryFldIds)
	 {
	      if ( $numListSubRecsBdryFldIds == 1)
	      {
	      	&formFinalRecords(\%allListBdryFldIdHash, "LISTSUBREC");
	      	$formCmpRecs = 1;
	      }
 	 }
 	 
 	
 	if (!($formCmpRecs ))
 	{
		# remove those fields that are part of list of sub-records and not the first fields in
		# that list of sub-records
		LOOP5:foreach $fldId_value (@listSubRecsFldIds_allLists)
		{
		  my $n;
		   foreach $n (0.. $#listBdryFldIds)
		   {
		     if ($fldId_value == $listBdryFldIds[$n])
		     {
		        delete $listBdryFldIds[$n];
			next LOOP5;
		     }
		   }

		}

		# store all the keys of the three hashes in one array
		push (@bdryFldIds, @subRecsBdryFldIds);
		push (@bdryFldIds, @listBdryFldIds);
		push (@bdryFldIds, @listSubRecsBdryFldIds);


		# for each key get its level id and boundary field id
		$fldIdHashRef = &dbGetLevelIds($dbh, $siteSelected, \@bdryFldIds);
		%fldIdHash = %$fldIdHashRef;

		#if any field has a boundary field that itself has another field as boundary field
		#we put such field first in the fieldIds array, so that it is mapped first to its boundary field
		#and then that boundary field can be mapped to its boundary field and so on
		foreach $fldId (keys %fldIdHash)
		{
			my @values;
			my $valuesRef;
			my $bdryFldId1;
			my $values1Ref;
			my @values1;
			my $bdryFldId2;
			my $values2Ref;
			my @values2;

				$valuesRef = $fldIdHash{$fldId};
				@values = @$valuesRef;
				$bdryFldId1 = $values[1];
				$values1Ref = $fldIdHash{$bdryFldId1};
				@values1 = @$values1Ref;
				if ($bdryFldId1 != $values1[1] )
				{
				 my @fldBdryFldIds;
					push (@fldBdryFldIds, $fldId);
					push (@fldBdryFldIds, $values[1]);
					push (@fldIds, \@fldBdryFldIds);
					delete $fldIdHash{$fldId}; 
				}

		}#end foreach $fldId

		# store all the level ids of the keys in an array
		foreach $fldId (keys %fldIdHash)
		{
			   my @values;
			   my $valuesRef;
				$valuesRef = $fldIdHash{$fldId};
				@values = @$valuesRef;
				push @levelIds, $values[0];
		}
		
		# sort the level ids in reverse
		@levelIds = sort{$b <=> $a} @levelIds;

		# arrange the fieldIds in decreasing order of their levelIds
		LOOP1:foreach $levelId (@levelIds)
		{
			foreach $fldId (keys %fldIdHash)
			{
				my @values;
				my $valuesRef;
					$valuesRef = $fldIdHash{$fldId};
					@values = @$valuesRef;
				if ($levelId == $values[0])
				{
				   my @fldBdryFldIds;
					push (@fldBdryFldIds, $fldId);
					push (@fldBdryFldIds, $values[1]);
					push (@fldIds, \@fldBdryFldIds);
					delete $fldIdHash{$fldId}; 
					next LOOP1;
				}
			}#end foreach $fldId
		}#end LOOP1:foreach $levelId


		foreach $index (0..$#fldIds )
		{
			$arrayRef = $fldIds[$index];
			@array = @$arrayRef;
			$fldId = $array[0];
			$bdryFldId = $array[1];

			# if a field does not have itself as its boundary field
			# check the hash to which the field belongs to
			if ($fldId != $bdryFldId )
			{
				if ( exists $allListBdryFldIdHash{$fldId} )
				{
					# identifies a list of sub-records
					$hashKey = "LISTSUBREC";
					my $allListSubRecsRef = $allListBdryFldIdHash{$fldId};
					my @allListSubRecs = @$allListSubRecsRef;
					
					# for each list of sub-records
					foreach $i (@allListSubRecs )
					{
						# get the first sub-record of the list
						@array1 = @$i;
						$j = @array1[0];
						
						# get the first field of the first sub-record
						@array2 = @$j;
						$k = @array2[0];

						# get the required details for relative position verification
						$relPos =    $k->{"RelPos"};
						$nodeNbr = $k->{"NodeNbr"};
						$relPosAdj = $k->{"RelPosAdj"};

						# search for the boundary field in the three hashes and form the final record
						&checkRelPos($bdryFldId, $relPos, $nodeNbr, $relPosAdj, $hashKey, \@array1, \%tempRecsHash, \%allLists, \%allListBdryFldIdHash);
					}#end foreach $i (@allListSubRecs )

				}#end if ( exists $allListBdryFldIdHash{$fldId} )

				elsif ( exists $tempRecsHash{$fldId} )
				{
					# identifies a sub-record
					$hashKey = "SUBREC";
					$array1Ref = $tempRecsHash{$fldId};
					@array3 = @$array1Ref;                                                              
					
					# for each sub-record
					foreach $l (@array3)
					{
					   # get the first field of the sub-record
					   @array4 = @$l;
					   $m = @array4[0];
					   
					   # get the required details for relative position verification
					   $relPos =    $m->{"RelPos"};
					   $nodeNbr = $m->{"NodeNbr"};
					   $relPosAdj = $m->{"RelPosAdj"};

					   # search for the boundary field in the three hashes and form the final record
					   &checkRelPos($bdryFldId, $relPos, $nodeNbr, $relPosAdj, $hashKey, \@array4, \%tempRecsHash, \%allLists, \%allListBdryFldIdHash);

					}#end foreach $l
				}#end elseif

				elsif ( exists $allLists{$fldId} )
				{
					# identifies a list
					$hashKey = "LIST";
					my $allListsArraysRef = $allLists{$fldId};
					my @allListsArray = @$allListsArraysRef;
					
					# for each list
					foreach $i (@allListsArray )
					{
						# get the first list item of the list
						@array1 = @$i;
						$j = @array1[0];

						# get the required details for relative position verification
						$relPos =    $j->{"RelPos"};
						$nodeNbr = $j->{"NodeNbr"};
						$relPosAdj = $j->{"RelPosAdj"};

						# search for the boundary field in the three hashes and form the final record
						&checkRelPos($bdryFldId, $relPos, $nodeNbr, $relPosAdj, $hashKey, \@array1, \%tempRecsHash, \%allLists, \%allListBdryFldIdHash);
					}#end foreach $i (@allListSubRecs )

				}#end elsif ( exists $allLists{$fldId})

			}#end if ($fldId != $bdryFldId
		}#foreach $index
	}#end if (!($formCmpRecs ))
	
}#end sub formCompleteRecords


# Routine to perform relative position verification
sub checkRelPos{
my ($bdryFldId, $relPos, $nodeNbr, $relPosAdj, $hashKey, $arrayRef, $tempRecsHashRef, $allListsRef, $allListBdryFldIdHashRef) = @_;
my @array = @$arrayRef;
my %tempRecsHash = %$tempRecsHashRef;
my %allLists = %$allListsRef;
my %allListBdryFldIdHash = %$allListBdryFldIdHashRef;
my $i1;
my @array11;
my $j1;
my @array21;
my $k1;
my $nodeNbrToCmp;
my $nodeDiff;
my $array1Ref;
my @array31;
my $l1;
my @array41;
my $m1;

	print("\n Searching boundary field contents for a $hashKey");
	
	# check the hash to which the boundary field belongs to
	if ( exists $allListBdryFldIdHash{$bdryFldId} )
	{
	  my $allListSubRecsRef = $allListBdryFldIdHash{$bdryFldId};
	  my @allListSubRecs = @$allListSubRecsRef;
	  
		print("\n Boundary field structure: List of SubRecords");
		# for each list of sub-records of the boundary
		LOOP2:foreach $i1 (@allListSubRecs )
		{
			# get the first sub-record of the list
			@array11 = @$i1;
			$j1 = @array11[0];
			
			# get the first field of the first sub-record
			@array21 = @$j1;
			$k1 = @array21[0];

			# get the required details for relative position verification
			$nodeNbrToCmp = $k1->{"NodeNbr"};
			$nodeDiff = $nodeNbr - $nodeNbrToCmp;
			
			# check the relative position condition
			if ($nodeDiff >= $relPos and $nodeDiff <= ($relPos + $relPosAdj) )
			{
				print("\nRelative Position satisfied");
				# if the boundary field has itself as its boundary field
				if( ($k1->{"FldId"}) == ($k1->{"bdryFldId"}) )
		   		{
					print("\nBoundary field has itself as boundary field");
					
					# if a final record with the boundary field already exists
					if ( exists $finalRecsHash{$nodeNbrToCmp} )
					{
					   my $arraysRef;
					   my %hash;

						print("Final record with the boundary field already exists");
						
						# create a new hash with the identifier( list, sub-record, list of sub-records)
						# as the key and the value is the reference to the array containing either of the
						# three possible contents
						$hash{$hashKey} = \@array;
						
						print("\nAdding to an existing final record");
						# add the hash to the proper final existing sub-record 
						$arraysRef = $finalRecsHash{$nodeNbrToCmp};
						push (@$arrayRef, \%hash);
					}
					else
					{
					   my %hash1;
					   my %hash2;
					   my @refArray;

						# create a hash with the identifier "LIST OF SUB_RECORDS" as the key
						# and the value is the reference to the array containing the boundary field contents
						$hash1{"LISTSUBREC"} = \@array11;
						
						# create a new hash with the identifier( list, sub-record, list of sub-records)
						# as the key and the value is the reference to the array containing either of the
						# three possible contents
						$hash2{$hashKey} = \@array;

						# create a new final record containing the boundary field contents
						# and the other structure(list or sub-records or list of sub-records) contents
						push (@refArray, \%hash1);
						push (@refArray, \%hash2);
						
						# create a hash with the node number of the boundary field as the key
						# and the value is the reference to the array containing the final record
						$finalRecsHash{$nodeNbrToCmp} = \@refArray;
						
						print("\nNew final record created");
					}
				}#end if( ($m1->{"FldId"}) == ($m1->{"bdryFldId"}) )
				else
				{
					# add the structure contents to the list of sub-records (boundary field )
					push( @$i1, @array);
					
					print("\nAdded the structure to the boundary list of sub-records");
				}
				last LOOP2;
			}#end if
		}#end LOOP2	
	}#end if exists
	elsif ( exists $tempRecsHash{$bdryFldId} )
	{
		print("\n Boundary field structure: SubRecord");
		$array1Ref = $tempRecsHash{$bdryFldId};
		@array31 = @$array1Ref;         
		
		# for each sub-record
		LOOP1:foreach $l1 (@array31)
		{
		
		   # get the first field of the sub-record
		   @array41 = @$l1;
		   $m1 = @array41[0];
		   
		   # get the required details for relative position verification
		   $nodeNbrToCmp = $m1->{"NodeNbr"};
		   $nodeDiff = $nodeNbr - $nodeNbrToCmp;
		   
		   # check the relative position condition
		   if ($nodeDiff >= $relPos and $nodeDiff <= ($relPos + $relPosAdj) )
		   {
		   	print("\nRelative Position Satisfied");
		
		   	# if the boundary field has itself as its boundary field
		   	if( ($m1->{"FldId"}) == ($m1->{"bdryFldId"}) )
		   	{
		   		print("\nBoundary field has itself as boundary field");
			
				# if a final record with the boundary field already exists
				if ( exists $finalRecsHash{$nodeNbrToCmp} )
				{
				  my $arraysRef;
				  my %hash;

					print("\nFinal record with the boundary field contents already exists");
					
					# create a new hash with the identifier( list, sub-record, list of sub-records)
					# as the key and the value is the reference to the array containing either of the
					# three possible contents
					$hash{$hashKey} = \@array;
					
					# add the hash to the proper final existing sub-record
					$arraysRef = $finalRecsHash{$nodeNbrToCmp};
					push (@$arraysRef, \%hash);
					
					print("\n Added to an existing final record");
				}
				else
				{
				   my %hash1;
				   my %hash2;
				   my @refArray;

					# create a hash with the identifier "SUBREC" as the key
					# and the value is the reference to the array containing the boundary field contents
					$hash1{"SUBREC"} = \@array41;
					
					# create a new hash with the identifier( list, sub-record, list of sub-records)
					# as the key and the value is the reference to the array containing either of the
					# three possible contents
					$hash2{$hashKey} = \@array;

					# create a new final record containing the boundary field contents
					# and the other structure(list or sub-records or list of sub-records) contents
					push (@refArray, \%hash1);
					push (@refArray, \%hash2);
					
					# create a hash with the node number of the boundary field as the key
					# and the value is the reference to the array containing the final record
					$finalRecsHash{$nodeNbrToCmp} = \@refArray;
					
					print("\nNew final record created");
				}
			}#end if( ($m1->{"FldId"}) == ($m1->{"bdryFldId"}) )
			else
			{
				# add the structure contents to the sub-record (boundary field )
				push( @$l1, @array);
				print("\nAdded the structure tothe boundary sub-record structure");
			}
			last LOOP1;
		   }

		}#end LOOP1
	}#end elsif
	elsif ( exists $allLists{$bdryFldId} )
	{
		my $allListsArrayRef = $allLists{$bdryFldId};
		my @allListsArray = @$allListsArrayRef;
		
		print("\n Boundary field structure: List");
		# for each list
		LOOP2:foreach $i1 (@allListsArray )
		{
			# get the first list item of the list
			@array11 = @$i1;
			$k1 = @array11[0];

			# get the required details for relative position verification
			$nodeNbrToCmp = $k1->{"NodeNbr"};
			$nodeDiff = $nodeNbr - $nodeNbrToCmp;
			
			# check the relative position condition
			if ($nodeDiff >= $relPos and $nodeDiff <= ($relPos + $relPosAdj) )
			{
				print("\nRelative Position Satisfied");
				
				# if the boundary field has itself as its boundary field
				if( ($k1->{"FldId"}) == ($k1->{"bdryFldId"}) )
				{
					print("\nBoundary field has itself as boundary field");
					
					# if a final record with the boundary field already exists
					if ( exists $finalRecsHash{$nodeNbrToCmp} )
					{
					   my $arraysRef;
					   my %hash;

						print("\nFinal record with the boundary field contents already exists");
						
						# create a new hash with the identifier( list, sub-record, list of sub-records)
						# as the key and the value is the reference to the array containing either of the
						# three possible contents
						$hash{$hashKey} = \@array;
						
						# add the hash to the proper final existing sub-record
						$arraysRef = $finalRecsHash{$nodeNbrToCmp};
						push (@$arrayRef, \%hash);
						
						print("\n Added to an existing final record");
					}
					else
					{
					   my %hash1;
					   my %hash2;
					   my @refArray;

						# create a hash with the identifier "LIST" as the key
						# and the value is the reference to the array containing the boundary field contents
						$hash1{"LIST"} = \@array11;
						
						# create a new hash with the identifier( list, sub-record, list of sub-records)
						# as the key and the value is the reference to the array containing either of the
						# three possible contents
						$hash2{$hashKey} = \@array;

						# create a new final record containing the boundary field contents
						# and the other structure(list or sub-records or list of sub-records) contents
						push (@refArray, \%hash1);
						push (@refArray, \%hash2);
						
						# create a hash with the node number of the boundary field as the key
					        # and the value is the reference to the array containing the final record
						$finalRecsHash{$nodeNbrToCmp} = \@refArray;
						
						print("\nNew final record created");
					}
				}#end if( ($k1->{"FldId"}) == ($k1->{"bdryFldId"}) )
				else
				{
					# add the structure contents to the sub-record (boundary field )
					push( @$i1, @array);
					
					print("\nAdded the structure to the boundary list structure");
				}
				last LOOP2;
			}#end if
		}#end LOOP2	
	}#end if exists

}#end sub checkRelPos

# Routine to form final records when only one of the three hashes has values
sub formFinalRecords {
my ($hashRef, $type) = @_;
my %hash = %$hashRef;
my $key;

	
  	print("\nConverting different types of structures in to the final record format");
   	if ($type eq "SUBREC")
   	{
   	   foreach $key ( keys %hash )
   	   {
   	   	my $arrayRef = $hash{$key};
   	   	my @array = @$arrayRef;
   	   	my $arraysRef;
      	
   	   	foreach $arraysRef ( @array )
   	   	{
   	   	  my @array2 = @$arraysRef;
   	   	  my $hashRef = @array2[0];
   	   	  my %hash;
   	   	  my @hashArray;
      	   
   	   	    $hash{$type} = $arraysRef;
   	   	    push (@hashArray, \%hash);
   	   	    $finalRecsHash{$hashRef->{"NodeNbr"}} = \@hashArray;
   	   	}#end foreach $arrayRef
   	   }#end foreach $key
   	}#end if ($type eq "SUBREC")
   
   	elsif ($type eq "LIST")
   	{
   		foreach $key ( keys %hash )
   	     {
   	       my $arrayRef = $hash{$key};
   	       my @array = @$arrayRef;
   	   	  my $listRef;
      	  
   	   	  foreach $listRef ( @array )
		  {
		    my %hash;
		    my @hashArray;
	
		    $hash{$type} = $listRef;
		    push (@hashArray, \%hash);
		    $finalRecsHash{$key} = \@hashArray;
		 }#end foreach $listRef
   	   }#end foreach $key
   
   	}#end elsif ($type eq "LIST")
   	
   	elsif ($type eq "LISTSUBREC")
   	{
   		foreach $key ( keys %hash )
		{
			my $allListSubRecsRef = $hash{$key};
			my @allListSubRecs = @$allListSubRecsRef;
			my $i;
			foreach $i (@allListSubRecs )
			{
			  my @array1 = @$i;
			  my $j = @array1[0];
			  my @array2 = @$j;
			  my $k = @array2[0];
					
			   my %hash;
			   my @hashArray;
				
			    $hash{$type} = $i;
			    push (@hashArray, \%hash);
		    	    $finalRecsHash{$k->{"NodeNbr"}} = \@hashArray;
			}
		}
   	}#end elsif ($type eq "LISTSUBREC")

}#end sub formFinalRecords


# Routine to check for mandatory field and display the final records
sub mandatoryFldCheckandPrintFinalRecsHash {
my $nodeNbr;
my $hashRef;
my @mandatoryFldIds;
my $mdFldId;
my $found = 0;
my $foundArrayRef;
my @foundArray;
my $secondFound = 0;
my $firstFound = 0;

	print("\nPerforming mandatory field check");
	
 	# get the mandatory field ids for this site
	@mandatoryFldIds = &dbGetMandatoryFldIds($dbh, $siteSelected);
	
	foreach $nodeNbr ( sort { $a <=> $b } keys %finalRecsHash )
	{
	  my $arrayRef;
	  my @array;
	  my $i;
	  
	  
	  	# get the array containing final records
		$arrayRef = $finalRecsHash{$nodeNbr};
		@array = @$arrayRef;
	
		printf FILE "\n\nNew Record:\n";
		if( ($#mandatoryFldIds + 1) > 0 )
		{
			LOOP:foreach $mdFldId (@mandatoryFldIds)
			{
			    undef $secondFound;
			    undef $firstFound ;
			    $i = 0;
			  
				
				# for each structure in the final record			
				LOOP1:foreach $hashRef ( @array )
				{
				 $found = 0;
				 
				 	# check if the mandatory field exists in the final record
					if ( defined $hashRef->{"SUBREC"} )
					{
						$found = &findFldIdinSubRec($mdFldId, $hashRef->{"SUBREC"});

					}
					if( !($found) )
					{
						if ( defined $hashRef->{"LIST"} )
						{
							$found = &findFldIdinList($mdFldId, $hashRef->{"LIST"});
						}
					}
					if( !($found) )
					{
						if ( defined $hashRef->{"LISTSUBREC"} )
						{
							($found, $foundArrayRef) = &findFldIdinListSubRec($mdFldId, $hashRef->{"LISTSUBREC"});
						}
					}
					
					if ($found)
					{
					  if ( !(defined($firstFound)))
					  {
					    # first occurence of this field has been found
					    $firstFound = $found;
					  }
					  else
					  {
					    # in case of any occurence other than the first in the final record
					    # delete that structure from the final record
					    delete $array[$i];

					  }
					}
					$i++;
					next LOOP1;
				}#end foreach $hashRef
				if (!($firstFound))
				{
					last LOOP;
				}
				else
				{
				   next LOOP;
				}
			}#end foreach $mdFldId
			
			# if the mandatory field has been found in the final record
			# display the record in the text area of the GUI
			if ($firstFound )
			{
				foreach $hashRef ( @array )
				{
					if ( defined $hashRef->{"SUBREC"} )
					{
						&printSubRec($hashRef->{"SUBREC"});
					}
					if ( defined $hashRef->{"LIST"} )
					{
						&printList($hashRef->{"LIST"});
					}
					if ( defined $hashRef->{"LISTSUBREC"} )
					{
						&printListSubRec($hashRef->{"LISTSUBREC"}, $foundArrayRef);
					}
				}#end foreach $hashRef
			}#end if
		}#end if
		else
		{
			# display the record in the text area of the GUI
			foreach $hashRef ( @array )
			{
				if ( defined $hashRef->{"SUBREC"} )
				{
					print("\n");
					&printSubRec($hashRef->{"SUBREC"});
				}
				if ( defined $hashRef->{"LIST"} )
				{
					print("\n");
					&printList($hashRef->{"LIST"});
				}
				if ( defined $hashRef->{"LISTSUBREC"} )
				{
					print("\n");
					&printListSubRec($hashRef->{"LISTSUBREC"});
				}
			}#end foreach $hashRef
		}
		
		print("\nInserting final extracted records into database");
		&dbInsertExtractedRecord( $dbh, $siteSelected, \@extractedRecsFldIds, \@extractedRecsListIds, \@extractedRecsParentIds ,\@extractedRecsValues );
		undef @extractedRecsFldIds;
		undef @extractedRecsValues;
		undef @extractedRecsListIds;
		undef @extractedRecsParentIds;
		
	}#end foreach $nodeNbr
	
}#end sub mandatoryFldCheckandPrintFinalRecsHash

# Routine to search for a mandatory fld in a subrecord
sub findFldIdinSubRec {
my ($mdFldId, $arrayRef) = @_;
my @array = @$arrayRef;
my $found = 0;

	LOOP:foreach  (@array)
	{
		if ( $mdFldId == $_->{"FldId"} )
		{
			$found = 1;
			last LOOP;
		}
	
	}
	
	return $found;
	
}#end sub findFldIdinSubRec

# Routine to search for a mandatory fld in a list
sub findFldIdinList {
my ($mdFldId, $arrayRef) = @_;
my @array = @$arrayRef;
my $j;
my @array2;
my $k;
my $found = 0;

	if ( $mdFldId == $array[0]->{"FldId"} )
	{
		$found = 1;
	}
	
  return $found;
	
}#end sub findFldIdinList


# Routine to search for a mandatory fld in a list of subrecords
sub findFldIdinListSubRec {
my ($mdFldId, $arrayRef) = @_;
my @array = @$arrayRef;
my $j;
my @array2;
my $k;
my @foundArray;
my $found;

	LOOP:foreach $j(@array)
	{
	  	@array2 = @$j;
		$found = 0;
		LOOP1: foreach $k (@array2)
		{
			if ( $mdFldId == $k->{"FldId"} )
			{
				$found = 1;
				last LOOP1;
			}
			
		}
		
		push @foundArray, $found;
	}
	
	$found = 0;
	LOOP: foreach ( @foundArray )
	{
	    if ($_ == 1)
	     {
	     $found = 1;
	     last LOOP;
	     }
	}
	return ($found, \@foundArray);
	
}#end sub findFldIdinListSubRec

# Routine to print a subrecord
sub printSubRec {
my ($arrayRef) = @_;
my @array = @$arrayRef;
my $fldId;
my $value;
my $listId;
my $i;
my $parentId;
my $parentName;
my $first = 1;
my $insertTab = 0;
my $prevParentName;
my $currentParentName;
my @parentIdName;
my $tab;
my $currentTab = 0; 
my $isSubRec = 0;
my $found = 0;
my $levelId;

	foreach  (@array)
	{
	
	     if ( ref($_) eq "HASH" )
	     {
	     
	        $fldId = $_->{"FldId"};
	        $value = $_->{"Text"};
	        $listId = $_->{"ListId"};
	        $levelId = $_->{"LevelId"};
		
		$found = 0;
		$isSubRec = 0;
				
		$parentId = &dbGetParentId($dbh, $siteSelected, $fldId);
		
		# get the name of the parent, only if the field belongs to a sub-record
		if ( $parentId != 0 )
		{
			$parentName = &dbGetFldName($dbh, $siteSelected, $parentId);
			$currentParentName = $parentName;
		}
	               
	        # check if it is the beginning of a new sub-record
	        if ($currentParentName ne $prevParentName )
	        {
	        	$isSubRec = 1;
	        	my $arrayRef;
	        	$tab = 0;
	        	
	        	# check if this parent name has been saved before
	        	LOOP:foreach $arrayRef ( @parentIdName )
	        	{
	        		$tab++;
	        		my @idNameArray = @$arrayRef;
	        		if ($parentId == $idNameArray[0] )
	        		{
	        			$found = 1;
	        			last LOOP;
	        		}
	        	}
	        	if ( !($found) )
	        	{
	        		# save the parent name and id
	        		my @array;
				push @array, $parentId;
				push @array, $parentName;
				push @parentIdName, \@array;
			}
	        	
	        }
	        else
	        {
	        	# indent the field according to its depth
	        	for ($i = 0; $i <= $levelId; $i++)
			{
				printf FILE "  ";  	
	        	}
	        	
	        	# print the field name and its text
	        	printf FILE "%10s :%s: \n", $_->{"FldName"}, $_->{"Text"};
	        }
	        
	        if ( $isSubRec )
	        {
	          my $i;
	        	if ( $found )
	        	{
	        	   # if the parent name has already been saved and displayed
	        	   # print the child field according to the depth of the parent
	        	   for ($i = 0; $i <= $tab; $i++)
	        	   {
	        		printf FILE "\t";  	
	        	   }
	        	
	        	}
	        
			if ( !($found) )
	        	{
	        	 	if ( defined ($parentName) )
	        	 	{
	        	 		  $prevParentName = $parentName;
	        	 		  
	        	 		  # indent the parent name according to its depth
	        	 		  for ($i = 0; $i < $levelId; $i++)
			 		  {
						printf FILE "  ";  	
	        	 		  }
	        	 		  
	        	 		  # print the name of the parent only once for all the children of this parent
	        	 		  printf FILE "%10s : \n", $parentName;
	        	 	 }
	        	  
	        	  	  # indent the field according to its depth
	        	 	  for ($i = 0; $i <= $levelId; $i++)
	        	 	  {
	        			printf FILE "  ";  	
	        	 	  }
	        	 	  
	        	 	  #print the field name and its text
	        	 	  printf FILE "%10s :%s: \n", $_->{"FldName"}, $_->{"Text"};
	        	}
	        }
	        
	        # save values to be inserted in to database
		push ( @extractedRecsFldIds, $fldId );
		push ( @extractedRecsValues, $value );
		push ( @extractedRecsListIds, $listId );
		push ( @extractedRecsParentIds, $parentId );
	      }
	      
	      
	      
	      if ( ref($_) eq "ARRAY" )
	      {
	      	foreach $i ( $_ )
	        {
	           my @array1 = @$i;
	           
	      	   foreach  (@array1)
		   {
		   	$levelId = $_->{"LevelId"};
		   		
			$found = 0;
			$isSubRec = 0;

			$parentId = &dbGetParentId($dbh, $siteSelected, $fldId);
			
			# get the name of the parent, only if the field belongs to a sub-record
	        	if ( $parentId != 0 )
			{
				$parentName = &dbGetFldName($dbh, $siteSelected, $parentId);
				$currentParentName = $parentName;
			}

			# check if it is the beginning of a new sub-record
			if ($currentParentName ne $prevParentName )
			{
				$isSubRec = 1;
				my $arrayRef;
				$tab = 0;

				# check if this parent name has been saved before
				LOOP:foreach $arrayRef ( @parentIdName )
				{
					$tab++;
					my @idNameArray = @$arrayRef;
					if ($parentId == $idNameArray[0] )
					{
						$found = 1;
						last LOOP;
					}
				}
				
				# save the parent name and id
				if ( !($found) )
				{
					my @array;
					push @array, $parentId;
					push @array, $parentName;
					push @parentIdName, \@array;
				}

			}
			else
			{
				# indent the field according to its depth
				for ($i = 0; $i <= $levelId; $i++)
				{
					printf FILE "  ";  	
				}
				
				# print the field name and its text
				printf FILE "%10s :%s: \n", $_->{"FldName"}, $_->{"Text"};
			}

			if ( $isSubRec )
			{
			  my $i;
			  
			  	# if the parent name has already been saved and displayed
	        	        # print the child field according to the depth of the parent
				if ( $found )
				{
				   for ($i = 0; $i <= $tab; $i++)
				   {
					printf FILE "\t";  	
				   }

				}

				if ( !($found) )
				{
					if ( defined ($parentName) )
					 {
					 	$prevParentName = $parentName;
					 
					 	  # indent the parent name according to its depth
					 	  for ($i = 0; $i < $levelId; $i++)
					 	  {
							printf FILE "  ";  	
					 	  }
					 	  
					 	  # print the name of the parent only once for all the children of this parent
					 	  printf FILE "%10s : \n", $parentName;
				 		}

				 	# indent the field according to its depth
				 	for ($i = 0; $i <= $levelId; $i++)
        			 	{
						printf FILE "  ";  	
				 	}
				 
				 	#print the field name and its text
				 	printf FILE "%10s :%s: \n", $_->{"FldName"}, $_->{"Text"};

			  	}#end if
	             	}#end if ( $isSubRec )
		   
		   	        	
		    	$fldId = $_->{"FldId"};
			$value = $_->{"Text"};
			$listId = $_->{"ListId"};
			
			# save values to be inserted in to database
			push ( @extractedRecsFldIds, $fldId );
			push ( @extractedRecsValues, $value );
			push ( @extractedRecsListIds, $listId );
			push ( @extractedRecsParentIds, $parentId );
	      	  }#end foreach @array1
	      }# $foreach $i    
	        	
	   }#end if
	   
	}#end foreach @array
	
}#end sub printSubRec

# Routine to print a list
sub printList {
my ($arrayRef) = @_;
my @array = @$arrayRef;
my $k;
my $fldId;
my $value;
my $listId = 0;
my $first = 1;
my $i;
my $levelId;
my $parentId;

	
	foreach $k(@array)
	{
		$levelId = $k->{"LevelId"};
		
		# print the name of the list field only once for all the list items
		if ( $first )
		{
		   for ($i = 0; $i < $levelId; $i++)
		   {
			printf FILE "  ";  	
		   }
		    printf FILE "%10s  : \n", $k->{"FldName"};
		   $first = 0;
		}
		
		for ($i = 0; $i <= $levelId; $i++)
		{
			printf FILE "    ";  	
		}
		   printf FILE ":%10s : \n", $k->{"Text"};
		
		$fldId = $k->{"FldId"};
		$value = $k->{"Text"};
		$parentId = &dbGetParentId($dbh, $siteSelected, $fldId);
		
		# save values to be inserted into database
		push ( @extractedRecsFldIds, $fldId );
		push ( @extractedRecsValues, $value );
		push ( @extractedRecsListIds, $listId );
		push ( @extractedRecsParentIds, $parentId );
		$listId++;
	}
	printf FILE "\n";
}#end sub printList

	
# Routine to print a list of subRecs
sub printListSubRec {
my ($arrayRef) = @_;
my @array = @$arrayRef;
my $j;
my @array2;
my $k;
my $fldId;
my $value;
my $listId = 0;
my $first = 1;
my $parentId;
my $parentName;
my $levelId;
my $i;
#my @foundArray = @$foundArrayRef;
my $found;
my @mandatoryFldIds;
my %fldHash;

	
	foreach $j(@array)
	{
		@array2 = @$j;
		LOOP:foreach $k (@array2)
		{
			$fldId = $k->{"FldId"};
			$value = $k->{"Text"};
			$levelId = $k->{"LevelId"};


			if ( $first )
			{
				$parentId = &dbGetParentId($dbh, $siteSelected, $fldId);
				
				# get the name of the parent, only if the field belongs to a sub-record
				if ( $parentId != 0 )
				{
					$parentName = &dbGetFldName($dbh, $siteSelected, $parentId);
				}

			}

			# print the name of the parent for the sub-record only once for all the children
			if ( ($first) && (defined ($parentName)) )
			{
				for ($i = 0; $i < $levelId; $i++)
				{
					printf FILE "  ";  	
				}
				printf FILE "%10s : \n", $parentName;	
				$first = 0;
			}
			
			for ($i = 0; $i <= $levelId; $i++)
			{
				printf FILE "  ";  	
			}

			printf FILE "%10s  :%s: \n", $k->{"FldName"}, $k->{"Text"};

			# save values to be inserted in to database
			push ( @extractedRecsFldIds, $fldId );
			push ( @extractedRecsValues, $value );
			push ( @extractedRecsListIds, $listId );
			push ( @extractedRecsParentIds, $parentId );
		}#end LOOP
		$listId++;
	}# for $j
	
	printf FILE "\n";
	
}#end sub printListSubRec


# Routine to add back all those LSBD list items that do not appear in the lists of sub-records
sub addUnmappedBdryLists {
my ($allLists, $allListBdryFldIdHash, $bdryFldId) = @_;
my %allLists = %$allLists;
my %allListBdryFldIdHash = %$allListBdryFldIdHash;
my $found = 0;
my $bdryFldIdArrayRef;
my @bdryFldIdArray;
my $bdryFldIdArrayRefs;	
my @bdryFldIdList;
my $bdryFldIdListItem;
my $bdryFldNodeNbr;
my $nodeNbr;
my @unmappedNodes;
my $l;
my $hash;
my $m;
my $i;
  
  	print("\nChecking for any unmapped lists and adding them to the list of sub records");
  
  	$bdryFldIdArrayRef = $allLists{$bdryFldId};
  	@bdryFldIdArray = @$bdryFldIdArrayRef;

	# for each list corresponding to the boundary field  	
  	foreach $bdryFldIdArrayRefs ( @bdryFldIdArray )
	{
  		@bdryFldIdList = @$bdryFldIdArrayRefs;
  		LOOP1:foreach $bdryFldIdListItem ( @bdryFldIdList )
  		   {
  		   	# get the node nmber of the boundary list item
  			$bdryFldNodeNbr = $bdryFldIdListItem->{"NodeNbr"};
  			
  			$found = 0;
  			
  			my $allListSubRecsRef = $allListBdryFldIdHash{$bdryFldId};
			my @allListSubRecs = @$allListSubRecsRef;
			
			# for each list of sub-records
			foreach $i (@allListSubRecs )
			{
			  my @array1;
			  my $j;
       		     	  
				@array1 = @$i;
				# for each sub-record
				foreach $j (@array1)
				{
				   my @array2;
  			  	   my $k;
  			  	 
  			  	 	# get the first field in the sub-record
					@array2 = @$j;
					$k = @array2[0];
					
					# check if the boundary list item exists as the first field in this sub-record
					$nodeNbr = $k->{"NodeNbr"};
					if ( $bdryFldNodeNbr == $nodeNbr )
					{
					  $found = 1;
					  next LOOP1;
					}
				}#end foreach $j
			}#end foreach $i (@allListSubRecs )
			  	
			# if the boundary list item was not found, save in it an array
  			if ( $found == 0 )
  			{
  				push(@unmappedNodes, $bdryFldIdListItem);
  				
  			}
  			
		    }#end LOOP1:foreach $bdryFldIdListItem
	}#end foreach $bdryFldIdArrayRefs
	
		
	LOOP2:foreach $hash (@unmappedNodes)
	{
	  my $nodeNbr21;
	  
	  		# get the node number of the boundary list item, not found in the list of sub-records
			$bdryFldNodeNbr = $hash->{"NodeNbr"};
		
			my $allListSubRecsRef = $allListBdryFldIdHash{$bdryFldId};
			my @allListSubRecs = @$allListSubRecsRef;
			
			# for each list of sub-records
			foreach $l (0..$#allListSubRecs )
			{
			   my @array1;
			   my $i;
			   my $j;
			   my @array2;
  		  	   my $k;
  		  	   my $nodeNbr1;
			   
				$i = $allListSubRecs[$l];
				
				# get the first sub-record in this list of sub-records
				@array1 = @$i;
				$j = @array1[0];
				
				# get the first field of the first sub-record
				@array2 = @$j;
				$k = @array2[0];
				
				# get the node number of the first field in the first sub-record
				$nodeNbr1 = $k->{"NodeNbr"};
				
				if ( ($l + 1) <= $#allListSubRecs )
				{
				  my $i1;
				  my @array11;
				  my $j1;
				  my @array21;
  				  my $k1;
  				  	
  				  	# get the next list of sub-records
					$i1 = $allListSubRecs[$l + 1];
					
					# get the first sub-record in this list of sub-records
					@array11 = @$i1;
					$j1 = @array11[0];
					
					# get the first field of the first sub-record
					@array21 = @$j1;
					$k1 = @array21[0];
					
					# get the node number of the first field in the first sub-record
					$nodeNbr21 = $k1->{"NodeNbr"};	
				}#end if ( ($l + 1) <= $#allListSubRecs )	
				
				
				if ( !( ($l + 1) <= $#allListSubRecs ) || ( ($bdryFldNodeNbr > $nodeNbr1) && ( $bdryFldNodeNbr < $nodeNbr21) ) )
				{
					# the boundary list item belongs to the first list
					# add the boundary list at the proper position in the list
					
					# for each sub-record in the first list
				  	foreach $m (0..$#array1)
					{
					  my $j3;
					  my @array23;
					  my $k3;
					  my $nodeNbr3;
  					  
  					  	# get the sub-record
						$j3 = @array1[$m];
						
						# get the first field of the sub-record and its node number
						@array23 = @$j3;
						$k3 = @array23[0];
						$nodeNbr3 = $k->{"NodeNbr"};
						
						if ( ($m + 1 ) <= $#array1)
						{
						   my $j4;
						   my @array24;
						   my $k4;
					           my $nodeNbr4;
					           
					           if (!($hash->{"ListId"} == 1) )
					           {
					           	# get the next sub-record
							$j4 = @array1[$m + 1];
							
							# get the first field of the sub-record and its node number
							@array24 = @$j4;
							$k4 = @array24[0];
							$nodeNbr4 = $k4->{"NodeNbr"};
							
							if ( ($bdryFldNodeNbr > $nodeNbr3) and ( $bdryFldNodeNbr < $nodeNbr4)  )
							{			
							   my @newArray1;
							   my @subRec;
							   
								#add the hash and reorder by nodenbr
								@newArray1 = @array1[0..$m];
								push (@subRec, $hash);
								push(@newArray1, \@subRec);
								push(@newArray1, @array1[$m+1..$#array1]);
								$allListSubRecs[$l] = \@newArray1;
								$allListBdryFldIdHash{$bdryFldId} = \@allListSubRecs;
								$found = 1;
								next LOOP2;

							}
						   }#end if (!($hash->{"ListId"} == 1) )
						}#end if
						else
						{
							if ($hash->{"ListId"} == 1)
							{
							 my @subRec;
							 my @listSubRec;
							 
							 # create a new list of sub-records and add it at the proper position
							    push @subRec, $hash;
							    push @listSubRec, \@subRec;
							    if ( ($l + 1) <= $#allListSubRecs )
							    {
							    	my @newAllListSubRecs;
							    	   @newAllListSubRecs =  @allListSubRecs[0..$l];
							    	   push (@newAllListSubRecs, \@listSubRec);
							    	   push (@newAllListSubRecs, @allListSubRecs[$l+1..$#allListSubRecs] );
							    	   $allListBdryFldIdHash{$bdryFldId} = \@newAllListSubRecs;
							    }
							    else
							    {
							    	push (@allListSubRecs, \@listSubRec);
							    	$allListBdryFldIdHash{$bdryFldId} = \@allListSubRecs;
							    }
							
							}#end if
							else
							{
							   my $relPos;
							   my $relPosAdj;
							   my $nodeNbr;
							   my $node;
							   my $nodeNbrToCmp;
							   my $nodeDiff;
							   my $list_copy;
							   my @subRec;
							   
							   	# add the boundary list item to the current list of sub-records at the proper position
								$relPos = $hash->{"RelPos"};
								$relPosAdj = $hash->{"RelPosAdj"};
								$nodeNbr = $hash->{"NodeNbr"};
								$node = pop @array1;
								@subRec = @$node;
								$nodeNbrToCmp = ($subRec[0])->{"NodeNbr"};
								$nodeDiff = $nodeNbr - $nodeNbrToCmp;
								if ($nodeDiff >= $relPos and $nodeDiff <= ($relPos + $relPosAdj) )
								{
								  my $list_copy;
								  my @subRec;
									push (@array1, $node);
									$list_copy = &copyList($hash);
									push (@subRec, $list_copy);
									push (@array1, \@subRec);
									$allListSubRecs[$l] = \@array1;
									$allListBdryFldIdHash{$bdryFldId} = \@allListSubRecs;

								}
								else
								{
									print("\nRelpos not satisfied")
								}
										
							}#end else
							next LOOP2;
						}#end else

					}#end foreach $m
				}#end if
				
			   }#end foreach $l
		
		}#end foreach $hash
  
    return \%allListBdryFldIdHash;
  
}#end sub addUnmappedBdryLists


# Routine to allow user to fine tune the values learned
sub fineTune {
my $frmFldLabel1;
my $frmFldLabel2;
my $dlgFldDesc1; 
my $dlgFldDesc2; 
my @frmFldEntry1;
my @frmFldEntry2;
my @txtFldFldId;
my @txtFldListId;
my @txtFldRelPos;
my @txtFldRelPosAdj;
my @txtFldFanout;
my @txtFldFanoutAdj;
my @txtFldLevel;
my @txtFldKeywords;
my @txtFldOmitwords;
my @txtFldBeginsWith;
my @txtFldEndsWith;
my @txtFldPreceededBy;
my @txtFldFollowedBy;
my @txtFldListSubRecRelPos;
my @txtFldListSubRecRelPosAdj;
my $siteId;
my @fldIds;
my $fldId;
my $fldDef;
my $i;
my $name;
my $relPos;
my $relPosAdj;
my $fanout;
my $fanoutAdj;
my $level;
my $keywords;
my $omitwords;
my $beginsWith;
my $endsWith;
my $preceededBy;
my $followedBy;
my $done;
my $button;
my $totFlds;
my @relPos;
my @relPosAdj;
my @fanout;
my @fanoutAdj;
my @level;
my @keywords;
my @omitwords;
my @beginsWith;
my @endsWith;
my @preceededBy;
my @followedBy;
my @listId;
my @listSubRecRelPos;
my @listSubRecRelPosAdj;
my $m;
my $fldId;
my $listId;
my $listSubRecRelPos;
my $listSubRecRelPosAdj;
my @fldId;

	# Display appropriate message on the status bar
	$status->configure(-text=> "Fine Tuning...");

	# Get the SITEID assigned to this site from the site table
	$siteId = &dbGetSiteId($dbh, $siteSelected);

	# Get the field ids for this site
	@fldIds = &dbGetFldIdsWithValues($dbh, $siteSelected);

	# Create a dialogbox
	$dlgFldDesc1 = $mainwin->DialogBox(-title=> "$siteSelected Fine Tuning ",
                                   	-buttons => [ "Update", "Cancel" , "View Others"],);
                                  
        $dlgFldDesc2 = $mainwin->DialogBox(-title=> "$siteSelected Fine Tuning ",
                                   	-buttons => [ "Update", "Cancel" ],);


	# Get the frame for the labels
	$frmFldLabel1 = $dlgFldDesc1->Frame();
	$frmFldLabel2 = $dlgFldDesc2->Frame();
	
	$frmFldLabel1->pack(-side=>"top", -fill=>'x');
	$frmFldLabel2->pack(-side=>"top", -fill=>'x');
	
	# Create the label line for the window
	$frmFldLabel1->Label(-text => "FIELDS", -width=>15)->pack(-side=>"left", -padx=>5);
	$frmFldLabel1->Label(-text => "LISTID", -width=>10)->pack(-side=>"left", -padx=>5);
	$frmFldLabel1->Label(-text => "KEYWORDS", -width=>20)->pack(-side=>"left", -padx=>5);
	$frmFldLabel1->Label(-text => "OMITWORDS", -width=>20)->pack(-side=>"left", -padx=>5);
	$frmFldLabel1->Label(-text => "BEGINSWITH", -width=>20)->pack(-side=>"left", -padx=>5);
	$frmFldLabel1->Label(-text => "ENDSWITH", -width=>20)->pack(-side=>"left", -padx=>5);
	$frmFldLabel1->Label(-text => "PRECEEDEDBY", -width=>20)->pack(-side=>"left", -padx=>5);
	$frmFldLabel1->Label(-text => "FOLLOWEDBY", -width=>20)->pack(-side=>"left", -padx=>5);
	
	$frmFldLabel2->Label(-text => "FIELDS", -width=>15)->pack(-side=>"left", -padx=>5);
	$frmFldLabel2->Label(-text => "LISTID", -width=>10)->pack(-side=>"left", -padx=>5);
	$frmFldLabel2->Label(-text => "RELPOS", -width=>10)->pack(-side=>"left", -padx=>5);
	$frmFldLabel2->Label(-text => "RELPOSADJ", -width=>10)->pack(-side=>"left", -padx=>5);
	$frmFldLabel2->Label(-text => "FANOUT", -width=>10)->pack(-side=>"left",-padx=>5);
	$frmFldLabel2->Label(-text => "FANOUTADJ", -width=>10)->pack(-side=>"left", -padx=>5);
	$frmFldLabel2->Label(-text => "LEVEL", -width=>10)->pack(-side=>"left", -padx=>5);
	$frmFldLabel2->Label(-text => "LTSRRELPOS", -width=>13)->pack(-side=>"left", -padx=>5);
	$frmFldLabel2->Label(-text => "LTSRRPADJ", -width=>20)->pack(-side=>"left", -padx=>5);

	# Rest of the text fields
	$i = 0;
	foreach $fldId (@fldIds) 
	{	

		# Get the field definition from the FINALVALUES table  
		$fldDef = &dbGetFldDef($dbh, $siteSelected, $fldId);
		
		for $m(0..$#{$fldDef})
		{
		
			$fldId = $fldDef->[$m][0];   	#$fldDef->{"FLDID"};
			$name = $fldDef->[$m][1];	#$fldDef->{"FLDNAME"};
			$relPos = $fldDef->[$m][6];  	#$fldDef->{"RELPOS"};
			$keywords = $fldDef->[$m][9];	#$fldDef->{"KEYWORDS"};
			$omitwords = $fldDef->[$m][10];	#$fldDef->{"OMITWORDS"};
			$relPosAdj = $fldDef->[$m][11];	#$fldDef->{"RELPOSADJ"};
			$listId =  $fldDef->[$m][13];	#$fldDef->{"LISTID"};
			$listSubRecRelPos = $fldDef->[$m][15];	#$fldDef->{"LISTSUBRECRELPOS"};
			$listSubRecRelPosAdj = $fldDef->[$m][16];	#$fldDef->{"LISTSUBRECRELPOSADJ"};
			$fanout = $fldDef->[$m][17];	#$fldDef->{"FANOUT"};
			$fanoutAdj = $fldDef->[$m][19];	#$fldDef->{"FANOUTADJ"};
			$level = $fldDef->[$m][18];	#$fldDef->{"LEVEL"};
			$beginsWith = $fldDef->[$m][20];	#$fldDef->{"BEGINSWITH"};
			$endsWith = $fldDef->[$m][21];	#$fldDef->{"ENDSWITH"};
			$preceededBy = $fldDef->[$m][22];	#$fldDef->{"PRECEEDEDBY"};
			$followedBy = $fldDef->[$m][23];	#$fldDef->{"FOLLOWEDBY"};
	
		push (@fldId, $fldId);
		# 1 char is 6 screen points - Note to self
		$frmFldEntry1[$i] = $dlgFldDesc1->Frame();
		$frmFldEntry1[$i]->pack(-fill=>'x');
		$frmFldEntry1[$i]->Label(-text=>"$name", -width=>15)->pack(-side=>"left",-padx=>5);
		
		$txtFldListId[$i] = $frmFldEntry1[$i]->Entry(-width=>4)->pack(-side=>"left", -padx=>23);
		$txtFldListId[$i]->insert(0, "$listId"); # Give the stored value 
		
		$frmFldEntry2[$i] = $dlgFldDesc2->Frame();
		$frmFldEntry2[$i]->pack(-fill=>'x');
		$frmFldEntry2[$i]->Label(-text=>"$name", -width=>15)->pack(-side=>"left",-padx=>5);
				
		$txtFldListId[$i] = $frmFldEntry2[$i]->Entry(-width=>4)->pack(-side=>"left", -padx=>23);
		$txtFldListId[$i]->insert(0, "$listId"); # Give the stored value 
		
		
		$txtFldKeywords[$i] = $frmFldEntry1[$i]->Entry(-width=>20)->pack(-side=>"left", -padx=>5);
		$txtFldKeywords[$i]->insert(0, "$keywords"); # Give the stored value 
		
		$txtFldOmitwords[$i] = $frmFldEntry1[$i]->Entry(-width=>20)->pack(-side=>"left",	-padx=>5);
		$txtFldOmitwords[$i]->insert(0, "$omitwords"); # Give the stored value 
				
		$txtFldBeginsWith[$i] = $frmFldEntry1[$i]->Entry(-width=>20)->pack(-side=>"left",	-padx=>5);
		$txtFldBeginsWith[$i]->insert(0, "$beginsWith"); # Give the stored value 
				
		$txtFldEndsWith[$i] = $frmFldEntry1[$i]->Entry(-width=>20)->pack(-side=>"left",	-padx=>5);
		$txtFldEndsWith[$i]->insert(0, "$endsWith"); # Give the stored value 
			
		$txtFldPreceededBy[$i] = $frmFldEntry1[$i]->Entry(-width=>20)->pack(-side=>"left",	-padx=>5);
		$txtFldPreceededBy[$i]->insert(0, "$preceededBy"); # Give the stored value 
				
		$txtFldFollowedBy[$i] = $frmFldEntry1[$i]->Entry(-width=>20)->pack(-side=>"left",	-padx=>5);
		$txtFldFollowedBy[$i]->insert(0, "$followedBy"); # Give the stored value 
		
		$txtFldRelPos[$i] = $frmFldEntry2[$i]->Entry(-width=>4)->pack(-side=>"left", -padx=>23);
		$txtFldRelPos[$i]->insert(0, "$relPos"); # Give the stored value 

		$txtFldRelPosAdj[$i] = $frmFldEntry2[$i]->Entry(-width=>4)->pack(-side=>"left",-padx=>23);
		$txtFldRelPosAdj[$i]->insert(0, "$relPosAdj"); # Give the stored value 

		$txtFldFanout[$i] = $frmFldEntry2[$i]->Entry(-width=>4)->pack(-side=>"left", -padx=>23);
		$txtFldFanout[$i]->insert(0, "$fanout"); # Give the stored value 

		$txtFldFanoutAdj[$i] = $frmFldEntry2[$i]->Entry(-width=>4)->pack(-side=>"left", -padx=>23);
		$txtFldFanoutAdj[$i]->insert(0, "$fanoutAdj"); # Give the stored value 

		$txtFldLevel[$i] = $frmFldEntry2[$i]->Entry(-width=>4)->pack(-side=>"left", -padx=>23);
		$txtFldLevel[$i]->insert(0, "$level"); # Give the stored value 
					
		$txtFldListSubRecRelPos[$i] = $frmFldEntry2[$i]->Entry(-width=>4)->pack(-side=>"left", -padx=>20);
		$txtFldListSubRecRelPos[$i]->insert(0, "$listSubRecRelPos"); # Give the stored value 
		
		$txtFldListSubRecRelPosAdj[$i] = $frmFldEntry2[$i]->Entry(-width=>4)->pack(-side=>"left", -padx=>50);
		$txtFldListSubRecRelPosAdj[$i]->insert(0, "$listSubRecRelPosAdj"); # Give the stored value 

		$i++;
		
	}#end $m
  }#end foreach $fldId

	# Get the total number of fields
	$totFlds = $#fldId;
	#print "Total Fields=" .  ($totFlds+1) . "\n";

	$done = 0;
	$i = 0;
	do {    
		# Show the dialog
		$button = $dlgFldDesc1->Show;

		if ($button eq "Update") 
		{
		  # Fetch the values entered in arrays
			for $i (0 .. $totFlds) 
			{
			        $listId = $txtFldListId[$i]->get;
				push(@listId, $listId);
				
				$keywords = $txtFldKeywords[$i]->get;
				push(@keywords, $keywords);
				
				$omitwords = $txtFldOmitwords[$i]->get;
				push(@omitwords, $omitwords);
				
				$beginsWith = $txtFldBeginsWith[$i]->get;
				push(@beginsWith, $beginsWith);
				
				$endsWith = $txtFldEndsWith[$i]->get;
				push(@endsWith, $endsWith);
				
				$preceededBy = $txtFldPreceededBy[$i]->get;
				push(@preceededBy, $preceededBy);
				
				$followedBy = $txtFldFollowedBy[$i]->get;
				push(@followedBy, $followedBy);
				
			}

			# Display appropriate message on the status bar
			$status->configure(-text=> "Updating values...");

			# Call the database function to update the values	
			&dbUpdateFldValues1($dbh, $siteSelected,\@fldId, \@listId, \@keywords, \@omitwords, \@beginsWith, \@endsWith, 
			                                    \@preceededBy, \@followedBy);

			# Display appropriate message on the status bar
			$status->configure(-text=> "Done...");

		} 
		elsif ($button eq "View Others") 
		{
		     my $done2 = 0;
		     my $i2 = 0;
			do {    
				# Show the dialog
				my $button2 = $dlgFldDesc2->Show;
		
				if ($button2 eq "Update") 
				{
				  # Fetch the values entered in arrays
					for $i2 (0 .. $totFlds) 
					{
					        $listId = $txtFldListId[$i2]->get;
						push(@listId, $listId);
						
						$relPos = $txtFldRelPos[$i2]->get;
						push(@relPos, $relPos);
						
						$relPosAdj = $txtFldRelPosAdj[$i2]->get;
						push(@relPosAdj, $relPosAdj);
						
						$fanout=$txtFldFanout[$i2]->get;
						push(@fanout, $fanout);
						
						$fanoutAdj = $txtFldFanoutAdj[$i2]->get;
						push(@fanoutAdj, $fanoutAdj);
						
						$level = $txtFldLevel[$i2]->get;
						push(@level, $level);
						
						$listSubRecRelPos = $txtFldListSubRecRelPos[$i2]->get;
						push(@listSubRecRelPos, $listSubRecRelPos);
						
						$listSubRecRelPosAdj = $txtFldListSubRecRelPosAdj[$i2]->get;
						push(@listSubRecRelPosAdj, $listSubRecRelPosAdj);
					}#end for $i2
		
					# Display appropriate message on the status bar
					$status->configure(-text=> "Updating values...");
		
					# Call the database function to update the values	
					&dbUpdateFldValues2($dbh, $siteSelected,\@fldId, \@listId, \@relPos, \@relPosAdj,
										\@fanout, \@fanoutAdj, \@level,\@listSubRecRelPos, \@listSubRecRelPosAdj);
		
					# Display appropriate message on the status bar
					$status->configure(-text=> "Done...");
		
				} #end if ($button2 eq "Update") 
				else
				{
					print "Cancelled out.\n";
					$done2 = 1;
				}
			} until $done2;
		}#end elsif ($button eq "View Others") 
		else
		{
			print "Cancelled out.\n";
			$done = 1;
		}
	} until $done;

	# Display appropriate message on the status bar
	$status->configure(-text=> "");
}

# Sub routine to create templates
sub templateCreate {
	my $button;
	my $done = 0;
	my $templateNbrFlds;
	my $templateName;

	# Display appropriate message on the status bar
	$status->configure(-text=> "Templae creation...");
	
	# Get the template name and number of fields
	do {    
		# Show the dialog
		$button = $dlgTemplateName->Show;
		if ($button eq "OK") 
		{
			$templateName = $txtTemplateName->get;
			$templateName =~ tr/a-z/A-Z/;
			$templateNbrFlds = $txtFldNbrFlds->get;

			if (length($templateName) && $templateNbrFlds > 0) 
			{
				print "$templateName Added\n";
				print "$templateNbrFlds Added\n";
				$done = 1;
			}
			else 
			{
				print "You didn't enter the correct Values!\n";
			}
		} 
		else
		{
			print "Cancelled out.\n";
			$done = 1;

			# Display appropriate message on the status bar
			$status->configure(-text=> "");

			return;
		}
	} until $done;

	# Get the field names through dialog
	my $dlgFldDesc = $mainwin->DialogBox(-title=> 
			"$templateName Template Field Definition", -buttons => [ "OK", "Cancel" ],);
	my $i = 0;
	my $frmFldLabel;
	my @frmFldEntry;
	my @txtFldName;
	my @fldName;

	$frmFldLabel = $dlgFldDesc->Frame();
	
	$frmFldLabel->pack(-side=>"top", -fill=>'x');
	
	# Create the label for the window
	$frmFldLabel->Label(-text => "Field Names", -width =>25)->pack(-side=>"left");

	# Rest of the text fields
	for ($i=0; $i < $templateNbrFlds; $i++)
	{ 
		$frmFldEntry[$i] = $dlgFldDesc->Frame();
		$frmFldEntry[$i]->pack(-fill=>'x');
		$txtFldName[$i] = $frmFldEntry[$i]->Entry(-width=>25)->pack(-side=>"left");
	}

	$done=0;
	my $filledAll=1;
	do {    
		# Show the dialog
		$button = $dlgFldDesc->Show;
		if ($button eq "OK") 
		{
			for ($i=0; $i < $templateNbrFlds; $i++) 
			{ 
				$fldName[$i] = $txtFldName[$i]->get;
				$fldName[$i] =~ tr/a-z/A-Z/;

				if (defined($fldName[$i]) && length($fldName[$i]))
				{
					print $fldName[$i] . " Added\n";
				}
				else 
				{
					my $fld=$i+1;
					print "You didn't enter name for field # " . $fld . "\n";
					$filledAll=0;
				}
			}
			# If all values were filled properly then close the loop
			if ($filledAll)
			{
				# Display appropriate message on the status bar
				$status->configure(-text=> "Inserting new template...");

				# Call a function to create the template in the database
				&dbtemplateCreate($dbh, $templateName, \@fldName);
				$done=1;

				# Display appropriate message on the status bar
				$status->configure(-text=> "Done...");
			}
		}
		else 
		{
			print "Cancelled out.\n";
			$done = 1;
		}
	} until $done;

	# Display appropriate message on the status bar
	$status->configure(-text=> "");
}

# Subroutine to associate template to a site
sub templateAssociate {

	my @sites;
	my @templates;
	my $button;
	my $done;

	# Display appropriate message on the status bar
	$status->configure(-text=> "Associating template...");
	
	# Select the site and its corresponding template to associate
	do {    
		# Show the dialog
		@sites = &dbGetSites($dbh);
		@templates = &dbGetTemplates($dbh);
		$beTemplateAssocSiteSel->configure(-choices=>\@sites);
		$beTemplateAssocTemplateSel->configure(-choices=>\@templates);
		$button = $dlgTemplateAssocSel->Show;
		if ($button eq "OK") {
			if (defined($siteSelected) && length($siteSelected) && 
			    defined($templateSelected) && length($templateSelected) ) 
			    {
				print "$siteSelected and $templateSelected Selected\n";
				$done = 1;
			} 
			else 
			{
				print "You didn't select a Site and its Template!\n";
			}
		} 
		else
		{
			print "Cancelled out.\n";
			$done = 1;

			# Display appropriate message on the status bar
			$status->configure(-text=> "");

			return;
		}
	} until $done;

	# Get the association between field names through dialog
	my $i = 0;
	my $dlgFldAssoc;
	my $frmFldAssocLabel;
	my @frmFldAssocEntry;
	my @siteFldIds;
	my @siteFldNames;
	my %siteFldNameIdx;
	my $siteFldName;
	my @siteFldNameMatch;
	my @siteFldIdMatch;
	my @templateFldIds;
	my @templateFldNames;
	my $templateFldName;
	my $filledAll;

	# Get field ids and names for the site selected 
	@siteFldIds = &dbGetFldIdsWithValues($dbh, $siteSelected);
	@siteFldNames = &dbGetFldNames($dbh, $siteSelected);

	# Associate site field name and id with a hash
	$i = 0;
	foreach $siteFldName (@siteFldNames) 
	{
		$siteFldNameIdx{$siteFldName} = $siteFldIds[$i];
		$i++;
	}

	# Get field ids and names for the template selected 
	@templateFldIds = &dbGetTemplateFldIds($dbh, $templateSelected);
	@templateFldNames = &dbGetTemplateFldNames($dbh, $templateSelected);

	# Declare the dialog
	$dlgFldAssoc = $mainwin->DialogBox(-title=> 
		"$siteSelected Template Field Association", -buttons => [ "OK", "Cancel" ],);

	# Start creating the various widgets on the dialog
	$frmFldAssocLabel = $dlgFldAssoc->Frame();
	
	$frmFldAssocLabel->pack(-side=>"top", -fill=>'x');
	
	# Create the label for the window
	$frmFldAssocLabel->Label(-text => "$templateSelected FIELDS", 
							-width =>24)->pack(-side=>"left", -padx=>5, -pady=>5);
	$frmFldAssocLabel->Label(-text => "$siteSelected FIELDS", 
							-width =>24)->pack(-side=>"left", -padx=>5, -pady=>5);

	# Associate the site fields with the template fields
	$i = 0;
	foreach $templateFldName (@templateFldNames) {
		@frmFldAssocEntry[$i] = $dlgFldAssoc->Frame();
		$frmFldAssocEntry[$i]->pack(-fill=>'x');
		$frmFldAssocEntry[$i]->Label(-text => $templateFldName,
							-width =>24)->pack(-side=>"left", -padx=>5, pady=>2); 
		$frmFldAssocEntry[$i]->BrowseEntry(-variable=> \$siteFldNameMatch[$i],
				-state=> 'normal',
				-choices=> \@siteFldNames)->pack(-side=>"left",-padx=>5, pady=>2);
		$i++;
	}

	my $dlgPromptSkip = $mainwin->DialogBox(-title=> "Warning!!", 
									-buttons=>[ "Skip", "Cancel" ]);
	my $frmPromptSkip = $dlgPromptSkip->Frame->pack(-side=>"top", -fill=>'x');
	my $frmPromptLbl = $frmPromptSkip->Label->pack(-side=>"left", -padx=>5, -pady=>5);

	$filledAll = 1;
	do {    
		# Show the dialog
		$button = $dlgFldAssoc->Show;
		if ($button eq "OK") 
		{
			for $i (0 .. $#templateFldNames)
			{ 

				if (length($siteFldNameMatch[$i])) 
				{
					print $siteFldNameMatch[$i] . " Added\n";
				} 
				else
				{
					$frmPromptLbl->configure(-text=> 
						"You didn't enter match for template field:  " . $templateFldNames[$i] . "\n");
					$button = $dlgPromptSkip->Show;
					if ($button ne "Skip")
					{
						$filledAll = 0;
						print "Cancelled out.\n";
					}
				}
			}

			# If all values were filled properly then insert the record 
			if ($filledAll) {
				# Get the fldIds for the site names selected
				foreach $siteFldName (@siteFldNameMatch)
				{
					push @siteFldIdMatch, $siteFldNameIdx{$siteFldName};
				}

				# Display appropriate message on the status bar
				$status->configure(-text=> "Creating the Association...");

				# Call a function to create the site in the database
				&dbInsertTemplateAssoc($dbh, $siteSelected, $templateSelected, \@siteFldIdMatch);

				# Display appropriate message on the status bar
				$status->configure(-text=> "Done");

				$done=1;
			} 
			else 
			{
				$filledAll=1;
			}
		}
		else
		{
			print "Cancelled out.\n";
			$done = 1;
		}
	} until $done;

	# Display appropriate message on the status bar
	$status->configure(-text=> "");
}

# Routine to clear up the text area
sub clearDisplay {

	# Display appropriate message on the status bar
	$status->configure(-text=> "");

	$textArea->delete('1.0','end');
	$efLbl->configure(-text=> "");
}

# Routine that displays the About Dialog
sub aboutMenu {
	$dlgAboutMenu->Show;
}

# Routine to select a file and open in textArea
sub openFile {

	my $value;
	my $done = 0;
	my $line;
	my $nodeNbr=0;

	# Free up the previous Tree and List structure
	if (defined $tree) {
		$tree = $tree->delete;
	}
	undef %htmlList;
	$txtFileName->delete(0, 'end');

	# Display appropriate message on the status bar
	$status->configure(-text=> "Opening file...");
	
	do {    
		 $value = $dlgOpenFile->Show;
		 if ($value eq "OK")
		 {
			my $file = $txtFileName->get;

			# Temporary
			$fileName = $file;
			
			print("\nFile selected: $file");
			# Check to see if the file name was entered
			if (length $file > 0)
			{

				# Get the nodes of HTML tree in a list 
				#%htmlList=&retHtmlList($file);

				# Make a tree of the HTML file 
				$tree = &retHtmlTree($file);
				$tree = &removeTextFormatingTags($tree);
				%htmlList = &retHtmlListFromTree($tree);

				$done = 1;
			}
		} 
		else
		{
		       # Cancel button pressed
			print "Cancelled out.\n";
			$done = 1;
		}
	} until $done;

	# Display appropriate message on the status bar
	$status->configure(-text=> "");
}	 

sub fileDialog {
    my $win = shift;
    my $fileName = shift;
    my $types;
    my $file;


    #   Type names		Extension(s)	Mac File Type(s)
    #
    #---------------------------------------------------------
    my @types =
      (["Html files", [qw/*.htm *.html *.HTM *.HTML/]],
       ["All files", '*.*']
      );
	$file = $win->getOpenFile(-filetypes => \@types);
   
	if (defined $file and $file ne '') {
		$fileName->delete(0, 'end');
		$fileName->insert(0, $file);
		$fileName->xview('end');

		# Open the file 
		$fileOpened = IO::File->new($file)
						or die "Could not open File \n";
	}
}

$dbh->disconnect;
