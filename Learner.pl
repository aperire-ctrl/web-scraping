use strict;
use Tk;
use Tk::BrowseEntry;
use English;
use Carp;
use Mysql;
require 'dbInterface.pl';
require 'HtmlInterface.pl';

use Tk::Frame;
use Tk::Balloon;
use Tk::DialogBox;
use IO::File;

# Declare global variables here
my $dbh;		 # Database Handle
my $dbname="project";	 # The database to connect to 
my $user="bindu";	 # The user name for the database
my $passwd="bindu";	 # The password for the database

my $fileOpened;  	 # Global Variable to indicate if the file is open
my %htmlList;		 # List holding all the nodes of the HTML page	
my $tree;		 # Tree for the HTML page 
my $siteSelected;	 # The site that will be learned
my $fieldDetailsRef;	 # The fields of the site
my $recordNbr=0;	 # Nbr of records learned
my $fldNbr;		 # Nbr of fields learned 
my $firstFldNodeNbr;	 # Node number of the first field of the record being learnt
my @fldNbrs;       	 # Array of Field Numbers
my @fldIds;		 # fldid of each field
my @fldDepths;		 # Depth of each field 
my @fldTagSeq;		 # Tag sequence of each field 
my @fldValues;		 # Values of each field 
my @fldKeywords;	 # Keywords for each field 
my @fldOmitwords;	 # Omitwords for each field 
my @fldBeginsWith;	 # BeginsWith for each field
my @fldEndsWith;	 # EndsWith for each field
my @fldPreceededBy;	 # PreceededBy for each field
my @fldFollowedBy;	 # FollwedBy for each field
my @fldRelPos;		 # Relative positions of each field with respect to the record boundary
my @recBdry_fldid;       # fldid of the record boundary for each field
my @fldListId;           # listid of each field
my @listSubrecRelPos;	 # listSubRecRelPos of each field
my @listSubRecBdry_fldid;# listSubRecBoundaryFieldId  of each field
my @incrementlistIds;    # Array containing values of$increment_listId of each field in a record
my @listSubRecs;         # Array containing values of $listSubRecs for each field in a record
my @savedFldNbrs;        # Array containing values of $savedFldNbr for each field
my @subRecFldsCounter;   # Array containbubg values of $subRecFldsCount for each field
my @fanout;		 # fanout of each field
my @treeLevel;		 # treeLevel of each field
my $HIGHVAL = 9999999;	 # Variable with a high value, assigned to variables when a proper values cannot be assigned to them
my $levelId = 1;	 	# Level Id of a field
my $parentId = 0;	 	# parent Id of a field
my $tableName;		 	# Name of a sub-record field, used to display during sub-record field definition 
my $numFields = 0;		# Number of fields in a record	
my $siteName;		 	# Name of the site
my %fldSeq_nodeNmbr_hash;	# Hash with fldSeq as the key and nodenumber,LevelId and FldId as values
my %nodeNmbr_fldid_hash; 	# Hash with nodenumber as the key and fldId as the value
my $ffnn_atLevel1;       	# First Field Node Number at Level 1
my $ffnn_atLvlsNtEq1;	 	# First field Node Number at Levels not equal to 1
my $sfnn_atLevel1;	 	# Other field's Node Number at level 1 	
my $listId = 0;          	# ListId for values learnt in a list
my $fldRelPos_ListId_2 = 0; 	# Relative Position of field with listid = 2
my $nodeNmbr_ListId_1 = 0;  	# Node Number of field with listId = 1
my $doneListItems = 0;      	# Variable set when the trainer clicks "DONE" button
my $nextListItem = 0;		# Variable set when the trainer clicks "DONE" button
my $listShown = 0;		# Variable set when the information frame for lists is shown for the first time
my $skip = 0;			# Variable set when user clicks "Skip" button of a frame
my $savedFldNbr;		# Field number of the first field in a list of sub-records 
my $copyFldNbr = 0;		# Variable set when the value of $savedFldNbr is retrieved
my $listSubRec = 0;		# Variable set in case of a list of sub-records
my $listSubRecBdryFldId = 0;	# List of Sub-Records Boundary Field Id of a field
my $listSubRecRelPos = 0;	# List of sub-Records relative position of a field
my $listSubRecBdryFldId_nodeNbr = 0;# Node Number of a list of sub-records boundary field
my %listIdHash;			# Hash with list id as the key and nodenumber as the value, 
				# used for a list item with list id of 1, in case of list of sub-records
my %listId2Hash;		# Hash with list id as the key and nodenumber as the value, 
				# used for a list item with list id of 2, in case of list of sub-records
my %fldId_nodeNbr_hash;		# Hash with field id as the key and nodenumber as the value,
				# used for a list item with list id of 1, in case of list of sub-records
my %fldId_relPos_hash;		# Hash with field id as the key and relative position as the value,
				# used for a list item with list id of 2
my $increment_listId = 0; 	# varaible used to increment the listId only once for the fields in each list
my %fldIdHash;			# Hash with field id as the key and value is reference to a hash that contains 
				# the values of list of sub records boundary field id and relative position
my $subRecFldsCount;		# Variable containing the number of fields in a sub-record, incase of list of 
				# sub-records, used to disable the "NEXT SUBRECORD FIELD" button
my $subRecFldCounter = 0;	# Value of this variable indicates the current field number in a sub-record
				# in case of list of sub-records
my $fieldDetailsCount = 0;	# Number of field in a record



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
my $helpmenu = $helpbutton->Menu();

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

$frm->Button(-text=>"Define new site",-width => 15,-command => \&siteCreate)->pack(-padx=>5, -pady=>5);
my $sLButton = $frm->Button(-text=>"Start Learning",-width => 15,-command => \&startLearning)->pack(-padx=>5, -pady=>5);
$frm->Button(-text=>"Clear Display",-width => 15,-command => \&clearDisplay)->pack(-padx=>5, -pady=>5);

$frm->Button(-text=>"EXIT",-width => 15,-command=>sub{$mainwin->destroy;})->pack(-padx=>5, -pady=>5);
# Status bar widget
my $status = $mainwin->Label(-width=>100,-relief => "sunken", -bd => 1, -anchor => 'w');
$status->pack(-side=>"bottom", -fill=>'y', -padx=>5, -pady=>5);

# Create the text area
my $textArea = $mainwin->Scrolled('Text')->pack;
$textArea->configure(-wrap=>'none');

# Create the earning area
my $learnFrame = $mainwin->Frame->pack;

# Display the Frame for entering values
my $lfLbl=$learnFrame->Label(-text =>"Learning site")->pack;

# Add new frames within the frame to format widgets
my $labelFrame=$learnFrame->Frame->pack;
my $entryFrame=$learnFrame->Frame->pack;
my $labelFrame1=$learnFrame->Frame->pack;
my $entryFrame1=$learnFrame->Frame->pack;
my $buttonFrame=$learnFrame->Frame->pack(-pady=>5);


# Now add the widgets
$labelFrame->Label(-text=>"Rec #", -width=>5)->pack(-side=>"left");
$labelFrame->Label(-text=>"Field Name", -width=>15)->pack(-side=>"left");
$labelFrame->Label(-text=>"Node #", -width=>10)->pack(-side=>"left", -padx=>5);
$labelFrame->Label(-text=>"Value", -width=>30)->pack(-side=>"left", -padx=>5);
$labelFrame->Label(-text=>"Keyword(s)", -width=>10)->pack(-side=>"left", -padx=>5);
$labelFrame->Label(-text=>"Omitword(s)", -width=>10)->pack(-side=>"left");
$labelFrame1->Label(-text=>"BeginsWith", -width=>10)->pack(-side=>"left", -padx=>5);
$labelFrame1->Label(-text=>"EndsWith", -width=>10)->pack(-side=>"left", -padx=>5);
$labelFrame1->Label(-text=>"PreceededBy", -width=>15)->pack(-side=>"left", -padx=>5);
$labelFrame1->Label(-text=>"FollowedBy", -width=>15)->pack(-side=>"left");

my $lfRecNbr = $entryFrame->Label(-width=>5)->pack(-side=>"left");
my $lfFldName = $entryFrame->Label(-width=>15)->pack(-side=>"left");
my $lfNodeNbr = $entryFrame->Entry(-width=>10)->pack(-side=>"left", -padx=>5);
my $lfFldValue = $entryFrame->Entry(-width=>30)->pack(-side=>"left", -padx=>5);
my $lfFldKeyword = $entryFrame->Entry(-width=>10)->pack(-side=>"left", -padx=>5);
my $lfFldOmitword = $entryFrame->Entry(-width=>10)->pack(-side=>"left");
my $lfFldBeginsWith = $entryFrame1->Entry(-width=>10)->pack(-side=>"left", -padx=>5);
my $lfFldEndsWith = $entryFrame1->Entry(-width=>10)->pack(-side=>"left", -padx=>5);
my $lfFldPreceededBy = $entryFrame1->Entry(-width=>15)->pack(-side=>"left", -padx=>5);
my $lfFldFollowedBy = $entryFrame1->Entry(-width=>15)->pack(-side=>"left");

my $lfBtnCapture = $buttonFrame->Button(-text=>"CAPTURE", -width=>9,-state=>'disabled', -command=>\&learnCapture)->pack(-side=>"left", -padx=>5);
my $lfBtnNextField = $buttonFrame->Button(-text=>"NEXT FIELD", -width=>10,-state=>'disabled', -command=>\&learnNextField)->pack(-side=>"left", -padx=>5);
my $lfBtnNextListItem = $buttonFrame->Button(-text=>"NEXT LIST ITEM", -width=>14,-state=>'disabled', -command=>\&learnNextListItem)->pack(-side=>"left", -padx=>5);
my $lfBtnDone = $buttonFrame->Button(-text=>"Done", -width=>4,-state=>'disabled', -command=>\&doneListItem)->pack(-side=>"left", -padx=>5);
my $lfBtnPrev = $buttonFrame->Button(-text=>"PREV", -width => 6,-state=>'disabled', -command => \&learnPrev)->pack(-side=>"left");

# Tie the filehandle to the text area
tie (*FILE, 'Tk::Text', $textArea);

print FILE "HTML file will be displayed here\n";

# Dialogs ...

# Site Name & Nbr of Fields Dialog
my $dlgSiteName = $mainwin->DialogBox(-title=> "Site Details", -buttons=>[ "OK", "Cancel" ]);
my $siteNameFrame=$dlgSiteName->Frame->pack(-side=>"top", -fill=>'x');
my $nbrFldFrame=$dlgSiteName->Frame->pack(-side=>"top", -fill=>'x');
$siteNameFrame->Label(-text => "Site Name:")->pack(-side=>"left", -padx=>5, -pady=>5);
my $txtSiteName = $siteNameFrame->Entry(-width => 25)->pack(-side=>"left", -padx=>5, -pady=>5);
$nbrFldFrame->Label(-text => "# of Fields:")->pack(-side=>"left", -padx=>5, -pady=>5);
my $txtFldNbrFlds = $nbrFldFrame->Entry(-width => 3)->pack(-side=>"left", -pady=>5);

# Select Site Dialog
my $dlgSiteSel = $mainwin->DialogBox(-title=> "Select the site",
                                   	-buttons => [ "OK", "Cancel" ],);
my $frmSiteSel = $dlgSiteSel->Frame->pack;
my $beSiteSel = $frmSiteSel->BrowseEntry(-variable=> \$siteSelected,
										   -state=> 'normal' )->pack;
# File Open Dialog
my $dlgOpenFile = $mainwin->DialogBox(-title=> "Display File",
	                                  -buttons => [ "OK", "Cancel" ],);
my $frmOpenFile = $dlgOpenFile->Frame;
$frmOpenFile->pack(-side=>"left", -fill=>'y', -expand=>'y', -padx=>5, -pady=>5);
$frmOpenFile->Label(-text=>"File to Open ", -width=>15, -padx=>5, -pady=>5)->pack;

my $frmFileTxt = $dlgOpenFile->Frame;
$frmFileTxt->pack(-side=>"left", -fill=>'y', -expand=>'y', -padx=>5, -pady=>5);

my $txtFileName = $frmFileTxt->Entry(-width=>30)->pack(-padx=>5, -pady=>5);
my $btnFileBrowse = $frmOpenFile->Button(-text => "Browse",
									     -command => sub {fileDialog($mainwin, $txtFileName)});
$btnFileBrowse->pack(-side=>"right");

# About Dialog 
my $dlgAboutMenu = $mainwin->DialogBox(-title=> "About Learner",
	                                  -buttons => [ "OK" ]);
$dlgAboutMenu->Label(-text=>"Learner Version 1.0")->pack;
$dlgAboutMenu->Label(-text=>"Copyright (C) 2000-2001 Paritosh Rohilla")->pack;

#List Info Window
my $dlgPromptList = $mainwin->DialogBox(-title=> "Information", 
													-buttons=>[ "OK" ]);
my $frmPromptList = $dlgPromptList->Frame->pack(-side=>"top", -fill=>'x');
   $frmPromptList->Label(-text => "Enter both first and second list Items")->pack(-side=>"left", 
																	-padx=>5, -pady=>5);
# Dialogs End ...

MainLoop;

# Routine to clear up the text area
sub clearDisplay 
{
	$textArea->delete('1.0','end');

}

# Routine to create a new site
sub siteCreate {
	my $button;
	my $done = 0;
	my $siteNbrFlds;
	#my $siteName;
	my $j;
	my $subRecRowsRef;
	my $i;
	my $NoError = 1;
	my $len;


    	# Clear entry fields
    	$len = length $txtSiteName->get;
	$len++;
	$txtSiteName->delete(0, $len);
	$txtSiteName->focus; 
	$len = length $txtFldNbrFlds->get;
	$len++;
	$txtFldNbrFlds->delete(0, $len);
	
	#set intial value
    	$levelId = 1;
    	
	# Display appropriate message on the status bar
	$status->configure(-text=> "New site creation...");
	
	# Get the site name and number of fields
	do {    
		# Show the dialog
		$button = $dlgSiteName->Show;
		if ($button eq "OK")
		{
			$tableName = $siteName = $txtSiteName->get;
			$siteName =~ tr/a-z/A-Z/;
			$numFields = $siteNbrFlds = $txtFldNbrFlds->get;

			if (length($siteName) && $siteNbrFlds > 0)
			{
				print "$siteName Added\n";
				print "$siteNbrFlds Added\n";
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
   
   	#call showTable routine repeatedly to show the table for entering field details
   	#including for any sub-record fields 
   
     	    if ($button eq "OK")
	    {
        	showTable();
			
		$done = 0;
		WLOOP: while(done)
		{
			 #Retrive any sub-record fields
	        	 $subRecRowsRef = &dbRetriveSubRecRows($dbh, $siteName, $levelId);
			 if ( ($#{$subRecRowsRef} + 1) < 1)
			 {
			 	$done = 1;
				last WLOOP;
			 }
			 
			 #Increment the level id for each level of hierarchy
		    	 $levelId = $levelId + 1;
		    	 
		    	 #get the parent id
		    	 for $i ( 0 .. $#{$subRecRowsRef} )
			 {
				   $parentId = $subRecRowsRef->[$i][0]; 
				   $tableName = $subRecRowsRef->[$i][1]; 
		
				   $NoError = showNumFldsWindow();	 
				   if( $NoError )
				   {
					showTable();
				   }
			  }#end for $i
			  	 			
	       }#end WLOOP 
	     }#end if	
}#end sub siteCreate	

# Routine to create a new site
sub showNumFldsWindow {
my $button;
my $done = 0;
my $subRecNbrFlds;
my $NoError = 1;


# Creating DialogBox to enter the number of fields for a subrecord
my $dlgSubRec = $mainwin->DialogBox(-title=> "Sub Record $tableName Details", -buttons=>[ "OK", "Cancel" ]);
my $subRecnbrFldFrame=$dlgSubRec->Frame->pack(-side=>"top", -fill=>'x');
$subRecnbrFldFrame->Label(-text => "Enter Number of Fields:")->pack(-side=>"left", -padx=>5, -pady=>5);
my $txtSubRecFldNbrFlds = $subRecnbrFldFrame->Entry(-width => 3)->pack(-side=>"left", -pady=>5);


	# Display appropriate message on the status bar
	$status->configure(-text=> "Sub Record: $tableName creation");
	
	# Get the number of fields for the sub record
	do {    
		# Show the dialog
		$button = $dlgSubRec->Show;
		$txtSubRecFldNbrFlds->focus;
		
		if ($button eq "OK")
		{
			
			$numFields = $subRecNbrFlds = $txtSubRecFldNbrFlds->get;

			if ($subRecNbrFlds > 0)
			{
				#print "$subRecNbrFlds Added\n";
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
			$NoError = 0;
			$done = 1;

			# Display appropriate message on the status bar
			$status->configure(-text=> "");
			return;
		}
	} until $done;
	
       return $NoError;
}#sub showNumFldsWindow
	
#Routine to accept the defintion of fields in a record or a sub-record
sub showTable
{
	# Get the field names through dialog
my $dlgFldDesc = $mainwin->DialogBox(-title=> "$tableName Field Definition",
									   -buttons => [ "OK", "Cancel" ],);
my $i = 0;
my $done = 0;
my $button;
my $frmFldLabel;
my @frmFldEntry;
my @txtFldName;
my @fldName;
my @fldSize;
my @txtFldType;
my @fldType;
my @txtFldMandatoryFlg;
my @fldMandatoryFlg;
my @txtFldListFlg;
my @fldListFlg;
my @txtFldSubRecordFlg;
my @fldSubRecordFlg;

	$frmFldLabel = $dlgFldDesc->Frame();
	$frmFldLabel->pack(-side=>"top", -fill=>'x');
	
	# Create the label for the window
	$frmFldLabel->Label(-text => "Field Names", -width =>25)->pack(-side=>"left");
	$frmFldLabel->Label(-text => "Type", -width =>5)->pack(-side=>"left");
	$frmFldLabel->Label(-text => "Mandatory", -width =>9)->pack(-side=>"left");
	$frmFldLabel->Label(-text => "List", -width => 5)->pack(-side=>"left");
	$frmFldLabel->Label(-text => "Sub Record", -width => 12)->pack(-side=>"left");

	# Rest of the text fields
	for ($i = 0; $i < $numFields; $i++) { 
		$frmFldEntry[$i] = $dlgFldDesc->Frame();
		$frmFldEntry[$i]->pack(-fill=>'x');
		$txtFldName[$i] = $frmFldEntry[$i]->Entry(-width=>25)->pack(-side=>"left");
		$txtFldType[$i] = $frmFldEntry[$i]->Entry(-width=>1)->pack(-side=>"left", padx=>15);
		$txtFldType[$i]->insert(0, "B"); # Give default value
		$txtFldMandatoryFlg[$i] = $frmFldEntry[$i]->Entry(-width=>1)->pack(-side=>"left", padx=>19);
		$txtFldMandatoryFlg[$i]->insert(0,"N"); # Give default value
		$txtFldListFlg[$i] = $frmFldEntry[$i]->Entry(-width=>1)->pack(-side=>"left", padx=>18);
		$txtFldListFlg[$i]->insert(0,"N"); # Give default value
		$txtFldSubRecordFlg[$i] = $frmFldEntry[$i]->Entry(-width=>1)->pack(-side=>"left", padx=>15);
		$txtFldSubRecordFlg[$i]->insert(0,"N"); # Give default value
	}
	
	#Show cursor in this text field
	$txtFldName[0]->focus;

	print("\n Accpeting field definition");
	$done = 0;
	my $filledAll = 1;
	do {    
		# Show the dialog
		$button = $dlgFldDesc->Show;
		if ($button eq "OK")
		{
			#Get each field definition
			for ($i = 0; $i < $numFields; $i++)
			{ 
				$fldName[$i] = $txtFldName[$i]->get;
				$fldName[$i] =~ tr/a-z/A-Z/;
				$fldType[$i] = $txtFldType[$i]->get;
				$fldType[$i] =~ tr/a-z/A-Z/;
				$fldMandatoryFlg[$i] = $txtFldMandatoryFlg[$i]->get;
				$fldMandatoryFlg[$i] =~ tr/a-z/A-Z/;
				$fldListFlg[$i] = $txtFldListFlg[$i]->get;
				$fldListFlg[$i] =~ tr/a-z/A-Z/;
				$fldSubRecordFlg[$i] = $txtFldSubRecordFlg[$i]->get;
				$fldSubRecordFlg[$i] =~ tr/a-z/A-Z/;
				

				if (defined($fldName[$i]) && length($fldName[$i])) 
				{
					print $fldName[$i] . " " . $fldSize[$i] . " Added\n";
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
				$status->configure(-text=> "Creating new site in the database...");

				# Call a function to create the site in the database
				
				&dbSiteCreate($dbh, $siteName, $levelId, $parentId, \@fldName, \@fldType, \@fldMandatoryFlg, \@fldListFlg, \@fldSubRecordFlg);
								
				$done=1;

				# Display appropriate message on the status bar
				$status->configure(-text=> "");
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
	
}#end sub showTable

# Start the learing process
sub startLearning {

my $button;
my $done = 0;
my $len;
my @sites;
	

	print("\n Starting Learning Process");		
	# Display appropriate message on the status bar
	$status->configure(-text=> "Learning Process (Site Selection)...");

	# Select the site 
	do {    
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
				
				#Enable proper buttons
				$lfBtnCapture->configure(-state=>'normal');
				$lfBtnNextField->configure(-state=>'normal');
			}
			else
			{
				print "You didn't select a Fld!\n";
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
	$status->configure(-text=> "Learning Process Contd...");

	# Display the Frame for entering values
	$lfLbl->configure(-text=> "Learning site $siteSelected");

	# Get the field definitions for the siteSelected
	$fieldDetailsRef = &dbGetFldDetails($dbh, $siteSelected);
	
	#Sort the field definitions on fldseq, as a number
	$fieldDetailsRef = &sortFldDetails($fieldDetailsRef);
	$fieldDetailsCount = $#{$fieldDetailsRef};
	
	# Reset the values
	$recordNbr = &dbGetMaxRecNbr($dbh, $siteSelected) + 1;
	$fldNbr = 0;

	# Show the record and field labels in the learning frame
	&setFldName();
	
	# Clear the current entries
	$len = length $lfNodeNbr->get;
	$len++;
	$lfNodeNbr->delete(0, $len);
	$len = length $lfFldValue->get;
	$len++;
	$lfFldValue->delete(0, $len);
	
	#Show the cursor in the proper text box
	$lfNodeNbr->focus;
	
}#end sub startLearning

#sub routine to sort the contents on fldseq, as numbers(not as characters/strings)
sub sortFldDetails {
my ($fieldDetailsRef) = @_;
my @array = @$fieldDetailsRef;
my $arrayRef;
my @fldSeqs;
my $fldSeq;
my @sortFldSeqsArray;
my $sortFldDetailsRef;

	foreach $arrayRef ( @array )
	{
		my $fldSeq = $arrayRef->[3];
		push @fldSeqs, $fldSeq;
		
	}#end foreach $arrayRef

	@fldSeqs = sort {$a<=>$b;} @fldSeqs;
	foreach $fldSeq ( @fldSeqs )
	{
	
		LOOP1:foreach $arrayRef ( @array )
		{
			my $fldSeq1 = $arrayRef->[3];
			if ( $fldSeq eq $fldSeq1 )
			{
				push @sortFldSeqsArray, $arrayRef;
				last LOOP1;
			}#end if
			
		}#end foreach $arrayRef
		
	}#end foreach $fldSeq
	
	$sortFldDetailsRef = \@sortFldSeqsArray;
	return $sortFldDetailsRef;
}#end sub sortFldDetails

#Routine to display the next appropriate field name to capture its details
sub setFldName {
my $subRecFlg;
my $listFlg;
my $fldName;
my $fldSeq;
my $done;
my $button;
my $listDone = 0;
	
	
	$done = 1;
	   
		
 	LOOP:	while(done)
 	{
 		#In case of a list of sub-records, after the last field in that sub-record(list item),
 		#the next field to be shown for the next list item, if the first field of that sub-record
 		#Retrive the previously saved field number of that field
 		if( $copyFldNbr )
		{
			$fldNbr = $savedFldNbr;
			$copyFldNbr = 0;
		}
	
		#Get detials of the field
	  	$fldName = $fieldDetailsRef->[$fldNbr][0];
	  	$listFlg = $fieldDetailsRef->[$fldNbr][1];
	  	$subRecFlg = $fieldDetailsRef->[$fldNbr][2];
	  	  
	  	
	  	if($subRecFlg eq 'Y' and $listFlg eq 'N')
	  	{
	      		#Enable approriate buttons
	  		enableDisbaleButtons('normal', 'disabled', 'disabled');
	  		
	  		#Display appropriate message on the status bar
	  		$status->configure(-text=> "Accepting Details for subrecord $fldName");
	  		
	  		#If a field is sub-record, move to the next field
	        	$fldNbr++;
       	  	}
	   
	  	elsif($subRecFlg eq 'Y' and $listFlg eq 'Y')
	  	{
	  		#List of sub-records
			#set variable 
			$listSubRec = 1;
			
			#Save the field number to be able to go back to this field, after all the
			#fields in the sub-record for the current list item are shown
			$savedFldNbr = $fldNbr;
			
			$fldSeq = $fieldDetailsRef->[$fldNbr][3];
			
			#get the number of fields in this sub-record
			$subRecFldsCount = &getSubRecFldsCount($fldSeq);
			
		  	#Enable proper buttons
		  	enableDisbaleButtons('normal', 'normal', 'normal');
		  
	   	   	# Display appropriate message on the status bar
	   		$status->configure(-text=> "Accepting Details for the  $fldName with subrecord");
	   	
	   		#Since the field is a sub-record, move to the next field
	           	$fldNbr++;
			
			#If the "Reminder/Informational" frame for lists is not shown previously
			#show the frame once for the whole session
			if ( $listShown == 0 )
			{
				do {    
					$button = $dlgPromptList->Show;
					if ($button eq "OK")
					{
						$listDone = 1;
					}
				   } until $listDone;
				   
				#set the varibale to indicate that the frame has been shown once
				$listShown = 1;
			  }
			  
         	}#end elsif
	 	elsif($subRecFlg eq 'N' and $listFlg eq 'Y')
	   	{
		  
		  #Enable proper buttons
		  enableDisbaleButtons('disabled', 'normal', 'normal');
	   	      
	   	  #Display appropriate message on the status bar
	   	  $status->configure(-text=> "Accepting Details for the list  $fldName");
	    
	    	  #If the "Reminder/Informational" frame for lists is not shown previously
		  #show the frame once for the whole session
	          if ( $listShown == 0 )
		  {
			do {    
				$button = $dlgPromptList->Show;
				if ($button eq "OK")
				{
					$listDone = 1;
				}
			   } until $listDone;
			   
			   #set the varibale to indicate that the frame has been shown once
			   $listShown = 1;
		   }
			  
	       }#end elsif
	       elsif($subRecFlg eq 'N' and $listFlg eq 'N')
	       { 	      
	       	  #Enable proper buttons
		  enableDisbaleButtons('normal', 'disabled', 'disabled');
		  
		  # Display appropriate message on the status bar
		  $status->configure(-text=> "Accepting Details for the field  $fldName");
		}
		  
		$subRecFlg = $fieldDetailsRef->[$fldNbr][2];
		if($subRecFlg eq 'Y')
		{
		    next LOOP;
		}
		else
		{
		   $done = 0;
		   last LOOP;
		}
	 }#end while
	
	#Display proper values in the frame
    	$lfRecNbr->configure(-text=>$recordNbr);
	$lfFldName->configure(-text=>$fieldDetailsRef->[$fldNbr][0]);
	
	
	$fldSeq = $fieldDetailsRef->[$fldNbr][3];
	
	#If a field is part of a sub-record, change label on the button
	if ($fldSeq =~ /^\d+\.\d+$/)
	{
	 	$lfBtnNextField->configure(-text=>"NEXT SUBREC FIELD", -width=>17);
        }
	else
	{
		$lfBtnNextField->configure(-text=>"NEXT FIELD", -width=>10);
        }
	
	
	if( $fldNbr == 0 )
	{
		#Disable "PREV" button for he first field of a record,
		#as its scope is only the current record
		$lfBtnPrev->configure(-state=>'disabled');
	}
	else
	{	#enable "PREV" button
		$lfBtnPrev->configure(-state=>'normal');
	}
	
	if( $listSubRec )
	{
		#Enable proper buttons
		enableDisbaleButtons('normal', 'normal', 'normal');
		
		#Increment the counter that indicates the current field number of a sub-record
		$subRecFldCounter++;
		
		#Disable button if the current field of the sub-record is the last field of that sub-record
		#to prevent moving beyond the sub-record limits
        	if ( $subRecFldCounter == $subRecFldsCount )
        	{
        		$lfBtnNextField->configure(-state=>'disabled');
        	}
	}
	
	$listFlg = $fieldDetailsRef->[$fldNbr][1];
	if ( $listFlg eq 'Y' && (!($listSubRec)) )
	{
		#Enable proper buttons
		enableDisbaleButtons('disabled', 'normal', 'normal');
	   	      
	   	# Display appropriate message on the status bar
	   	$status->configure(-text=> "Accepting Details for the list  $fldName");
	    
	    	#If the "Reminder/Informational" frame for lists is not shown previously
		#show the frame once for the whole session
	        if ( $listShown == 0 )
		{
			do {    
				$button = $dlgPromptList->Show;
				if ($button eq "OK")
				{
					$listDone = 1;
				}
			   } until $listDone;
			   
			  #set the varibale to indicate that the frame has been shown once
			  $listShown = 1;
		}#end if
	}#end if
	print("\nAccepting details for $fldName");
}#end sub setFldName


# Capture the text held by the node
sub learnCapture {
my $len;
my $nodeNbr;
my $fldSeq;
my $fldNum;

	# Get the node number entered 
	$nodeNbr = $lfNodeNbr->get;

	# If nothing is entered, come out
	if (length $nodeNbr == 0)
	{
		return;
	}

	# Clear the current entry
	$len = length $lfFldValue->get;
	$len++;
	$lfFldValue->delete(0, $len);
	
	# Put the text of the node in the text area
	$lfFldValue->insert(0, $htmlList{$nodeNbr});

		
	$fldNum = $fldNbr;
	if($fldNum < $#{$fieldDetailsRef})
	{
		$fldNum++;
		$fldSeq = $fieldDetailsRef->[$fldNum][3];
		
		#set the proper label for the button
		if ($fldSeq =~ /^\d+\.\d+$/)
		{
		 $lfBtnNextField->configure(-text=>"NEXT SUBREC FIELD", -width=>17);
	        }
		else
		{
		 $lfBtnNextField->configure(-text=>"NEXT FIELD", -width=>10);
         	}
		 
	}#end if	 
		
}#end sub learnCapture

#Routine to get the number of fields in the subrecord
sub getSubRecFldsCount {
my ($fldSeq) = @_;
my $i = 0;
my $count = 0;
my @fldSeqs;
  
  	while ( defined ($fieldDetailsRef->[$i][0]) )
  	{
  		if ($fieldDetailsRef->[$i][2] ne 'Y') 
  		{
  			push (@fldSeqs, $fieldDetailsRef->[$i][3]);
  		}
  		$i++;
  	}
  	
  	foreach (@fldSeqs)
  	{
  		if(/$fldSeq/)
  		{
  			$count++;
  		}
  	}
  	
  	return $count;
  	
}#end getSubRecFldsCount


# Capture the value for the next field
sub learnNextField {
my $len;
my $fldValue;
my $fldKeyword;
my $fldOmitword;
my $fldBeginsWith;
my $fldEndsWith;
my $fldPreceededBy;
my $fldFollowedBy;
my $fldRelPos = 0;
my $recBdry_fldid = 0;
my $nodeNbr;
my $tagSeq;
my $depth;
my $fanout;
my $treeLevel;
my $fldId;
my $done;
my $dlgPromptSkip;
my $frmPromptSkip;
my $button;
my $fldname;
my $totNodes;
my $lastChar;
my $level;
my $found;
my $hashkey;
my @fldSeqArray;
my $lastArrItem;
my $prevArrItem;
my $done;
my $len1;
my $len2;
my $strToCmp1;
my $strToCmp2;
my $frstChar_Last;
my $frstChar_Prev;
my $i;
my $text;
	
	print("\nLearning values");
	undef $button;
	
	#clear values
	if ( !$listSubRec )
	{
		$listSubRecBdryFldId = 0;
		$listSubRecRelPos = 0;
		
	}


	# Get the values entered earlier for a field, before proceeding to the next
	$nodeNbr = $lfNodeNbr->get;
	$fldValue = $lfFldValue->get;
	$fldKeyword = $lfFldKeyword->get;
	$fldOmitword = $lfFldOmitword->get;
	$fldBeginsWith = $lfFldBeginsWith->get;
	$fldEndsWith = $lfFldEndsWith->get;
	$fldPreceededBy = $lfFldPreceededBy->get;
	$fldFollowedBy = $lfFldFollowedBy->get;
	
	#Apply default values
	if ( !( $fldPreceededBy) )
	{
		$fldPreceededBy = "Nothing";
	} 
	
	if ( !( $fldFollowedBy) )
	{
		$fldFollowedBy = "Nothing";
	} 

    
    	#if a warning is not already displayed, 
	# If nothing is entered, and a warning has not already been displayed, display warning
	if ( $skip != 1)
	{
		if (length $fldValue == 0 or length $nodeNbr == 0) 
		{
			$text = "Do you want to skip this field?";
			do {   
				$button = showDlgPrompt($text);
				if ($button ne "Skip")
				{
					print "Cancelled out.\n";
				}
				$done = 1;
			} until $done;

			return   if ($button eq "Cancel");
		}
	}
	
	if ($skip == 1 )
	{
		$button = "Skip";
	}
	
	
   	# Get the tag sequence and depth of the node
   	if ($button ne "Skip")
   	{
   	
   		($tagSeq, $depth, $fanout, $treeLevel) = &getNodeInfo($tree, $nodeNbr) if ($button ne "Skip");
		$fldId = $fieldDetailsRef->[$fldNbr][5];


		#in case of list of subrecords, increment listId if it is not already been incremented
		if( $listSubRec )
		{
			if ( !$increment_listId )
			{
				$listId++;
				$increment_listId = 1;
			}
		}

	    	#Calculation of Boundary Field and Relative Positions for List of SubRecords
		if ( $listSubRec )
		{
			if ( ( $listId == 0 ) || ( $listId == 1 ) )
			{
				#If fldseq ends in 1, it is the first field in the subrecord
				$fieldDetailsRef->[$fldNbr][3] =~ /^\d{1}\.\d*(\d)$/;
				if ( $1 == 1 )
				{
					#boundary field is the current field
					$listSubRecBdryFldId = $fieldDetailsRef->[$fldNbr][5];
					
					#save the node number of the boundary field for the relative position calculations
					if ( $nodeNbr )
					{
						$listSubRecBdryFldId_nodeNbr = $nodeNbr;
					}
				}

				if ( $listSubRecBdryFldId_nodeNbr )
				{

					#calculate the relative position
					$listSubRecRelPos = $nodeNbr - $listSubRecBdryFldId_nodeNbr;
				}
				else
				{
					#If a boundary field's node number couldn't be saved previously
					#assign a high value for relative position
					$listSubRecRelPos = $HIGHVAL;
				}

				#save the boundary field id and the relative position values to be assigned
				#later to other list items
				my %recBdry_relPos_hash;
					$recBdry_relPos_hash{"RecBdry"} = $listSubRecBdryFldId;
					$recBdry_relPos_hash{"RelPos"} = $listSubRecRelPos;
					$fldIdHash{$fieldDetailsRef->[$fldNbr][5]} = \%recBdry_relPos_hash;

			}#end if ( $listId == 1 )
		}#end if ( $listSubRec )

	    	#Get the field name
		$fldname = $lfFldName->cget('text');
		

		#Create Hash with "fldSeq" as KEY
		#Value is an array containing node number, level id and field id
		#Save the values to be used for relative position calculations
		
		
		#if a field is a list, if it's fldseq does not end in 1,
		#remove that field from boundary field calculations,
		#as that field may be mapped to another field which may be a list-don't save it's values
		
		#If a field is part of a sub-record, and is not the first field in that sub-record,
		#remove that field from boundary field calculations-don't save it's values
		
		if ( ($fieldDetailsRef->[$fldNbr][1]) eq 'Y' )
		{
			$fieldDetailsRef->[$fldNbr][3] =~ /^\d{1}\.\d*(\d)$/;
			if ( $1 == 1) 
			{
				$fldSeq_nodeNmbr_hash{$fieldDetailsRef->[$fldNbr][3]}[0] = $nodeNbr;
				$fldSeq_nodeNmbr_hash{$fieldDetailsRef->[$fldNbr][3]}[1] = $fieldDetailsRef->[$fldNbr][4];
				$fldSeq_nodeNmbr_hash{$fieldDetailsRef->[$fldNbr][3]}[2] = $fieldDetailsRef->[$fldNbr][5];
			}
			
		}
		else
		{
		  	if ( $fieldDetailsRef->[$fldNbr][3] =~ /^\d+\.\d+$/ )
			{
				$fieldDetailsRef->[$fldNbr][3] =~ /^\d{1}\.\d*(\d)$/;
				if ( $1 == 1) 
				{
					$fldSeq_nodeNmbr_hash{$fieldDetailsRef->[$fldNbr][3]}[0] = $nodeNbr;
					$fldSeq_nodeNmbr_hash{$fieldDetailsRef->[$fldNbr][3]}[1] = $fieldDetailsRef->[$fldNbr][4];
					$fldSeq_nodeNmbr_hash{$fieldDetailsRef->[$fldNbr][3]}[2] = $fieldDetailsRef->[$fldNbr][5];
				}	
			}
			else
			{
				$fldSeq_nodeNmbr_hash{$fieldDetailsRef->[$fldNbr][3]}[0] = $nodeNbr;
				$fldSeq_nodeNmbr_hash{$fieldDetailsRef->[$fldNbr][3]}[1] = $fieldDetailsRef->[$fldNbr][4];
				$fldSeq_nodeNmbr_hash{$fieldDetailsRef->[$fldNbr][3]}[2] = $fieldDetailsRef->[$fldNbr][5];
			}
		}
		
		
		#create Hash with nodenbr as key and fldid as value
		#used for boundary field's calculations
		#in case of multiple fields sharing the same node number, we only save the first
		#node number w.r.t the first field number, else, it would override the value, each time
		#we learn a different field, but with the same node number. Just saving the first works
		
		if ( not exists $nodeNmbr_fldid_hash{$nodeNbr} )
		{
			$nodeNmbr_fldid_hash{$nodeNbr} = $fieldDetailsRef->[$fldNbr][5];
		}

		
		# save the node number of the first field of this record 
		if ( !defined $ffnn_atLevel1 )
		{
			$ffnn_atLevel1 = $nodeNbr;

		}

		#Relative Position calculation for listItems 
		if($listId == 0 || $listId == 1)
		{
			if($listId == 1)
			{
				#save the node number of the first list item
				$nodeNmbr_ListId_1 = $nodeNbr;


				if ( $listSubRec || $doneListItems )
				{
					#incase of list of sub-records, we have to save the nodenumber info
					#for all the fields in the subrecord, to be used for calculation
					#of relative position and boundary field for all the fields in the sub-record
					#with list id == 2

					if ( not exists $listIdHash{$listId} ) 
					{
						$fldId_nodeNbr_hash{$fieldDetailsRef->[$fldNbr][5]} = $nodeNbr;
						$listIdHash{$listId} = \%fldId_nodeNbr_hash;
					}
					else
					{
						my $hashRef = $listIdHash{$listId};
						my %fldIdNodeNbrHash = %$hashRef;
						$fldIdNodeNbrHash{$fieldDetailsRef->[$fldNbr][5]} = $nodeNbr;
						$listIdHash{$listId} = \%fldIdNodeNbrHash;
						print " ";
					}
				}


			}#end if($listId == 1)


		#Relative position and boundary field calculation for all fields at level 1
		
		my $lowFldId_AtLvl1;
		if ( $fieldDetailsRef->[$fldNbr][4] == 1)
		{
			#get the lowest field id of all the fields at level 1
			$lowFldId_AtLvl1 = &dbGetLowFldId($dbh, $siteSelected, 1);
			
			#calculate the rlative position and boundary field
			if ( $lowFldId_AtLvl1 == $fieldDetailsRef->[$fldNbr][5])
			{
				#if the lowest field at level 1, is the current field
				#save its node number
				$fldRelPos = $nodeNbr - $ffnn_atLevel1;
				$recBdry_fldid = $nodeNmbr_fldid_hash{$ffnn_atLevel1};
				$sfnn_atLevel1 = $nodeNbr;
			}
			else
			{
				$fldRelPos = $nodeNbr - $sfnn_atLevel1;
				$recBdry_fldid = $nodeNmbr_fldid_hash{$sfnn_atLevel1};
			}
		}
		

		#Relative position RP and boundary field BF calculations for all the fields at levels other than 1
		if ( $fieldDetailsRef->[$fldNbr][4] != 1 )
		{

			$found = 0;
			$level = $fieldDetailsRef->[$fldNbr][4];

			
			$fieldDetailsRef->[$fldNbr][3] =~ /^\d{1}\.\d*(\d)$/;
			
			#calculate RP and BF for the first field of the sub-record at this level
			if ( $1 == 1)
			{
			  WHLOOP: while ( $found == 0 )
			  {
				$level = $level - 1;
				if ( $level == 1 )
				{
					$ffnn_atLvlsNtEq1 = $ffnn_atLevel1;
					$recBdry_fldid = $nodeNmbr_fldid_hash{$ffnn_atLvlsNtEq1};
					$found = 1;
					last WHLOOP;
			        }
				else
				{
					for $hashkey (keys %fldSeq_nodeNmbr_hash) 
					{
						#for all the field sequences at $level, sort the fldseq's 
						#including the current fldseq and choose the one immediately below itself
						#if it begins with the same character as the current fieldseq

						#Get FLDSEQ's at $level
						if ( $fldSeq_nodeNmbr_hash{$hashkey}[1] == $level )
						{
							push (@fldSeqArray, $hashkey);
						}
					}


					#Sort fldSeq's at $level including current fldSeq
					$done = 0;
					if( scalar(@fldSeqArray) > 0)
					{
						push (@fldSeqArray, $fieldDetailsRef->[$fldNbr][3]);
						@fldSeqArray = sort @fldSeqArray;

						#Get current fldSeq and the one previous to it
						#Select it if both begin with the same character
						while ( ($done == 0) && (@fldSeqArray) )
						{
							$lastArrItem = pop (@fldSeqArray);
							if( $lastArrItem eq $fieldDetailsRef->[$fldNbr][3])
							{
								$done = 1;
								if( scalar(@fldSeqArray) > 1)
								{
									$prevArrItem = pop (@fldSeqArray);
									$lastArrItem =~ /(\d{1})\.\d*/;
									$frstChar_Last = $1;

									$prevArrItem =~ /(\d{1})\.\d*/;
									$frstChar_Prev = $1;

									if( $frstChar_Last eq $frstChar_Prev)
									{

									 	$ffnn_atLvlsNtEq1 = $fldSeq_nodeNmbr_hash{$prevArrItem}[0];
										$recBdry_fldid = $fldSeq_nodeNmbr_hash{$prevArrItem}[2];
										$found = 1;

									}
								   }
							  }
						  }#End while
					    }#End if
				}#End else			
			}#End while
		 }#End if

		 #if the field is not the first field of the sub-record at this level
		 else
		 {
			$found = 0;
			$level = $fieldDetailsRef->[$fldNbr][4];
			$i = 1;
			WHLOOP1: while ( $found == 0 )
			{
				if ( $level == 1)
				{
					$ffnn_atLvlsNtEq1 = $ffnn_atLevel1;
					$recBdry_fldid = $nodeNmbr_fldid_hash{$ffnn_atLvlsNtEq1};
					$found = 1;
					last WHLOOP1;
				 }
				else
				{
					foreach $hashkey (keys %fldSeq_nodeNmbr_hash) 
					{
						#If field Seq ends in 1 and is at $level

						$hashkey =~ /^\d{1}\.\d*(\d)$/;
						$lastChar = $1;
						if( ( $level eq  $fldSeq_nodeNmbr_hash{$hashkey}[1]) && ( $lastChar == 1 ) )
						{
							#If it has same characters upto but last $i characters
							$len1 = length( $hashkey );
							$len2 = length( $fieldDetailsRef->[$fldNbr][3] );
							$strToCmp1 = substr( $hashkey, 0 , ($len1 - $i) );
							$strToCmp2 = substr( $fieldDetailsRef->[$fldNbr][3], 0 , ($len2 - 1) );
								
								
							if( $strToCmp1 eq $strToCmp2 )
							{
								$ffnn_atLvlsNtEq1 = $fldSeq_nodeNmbr_hash{$hashkey}[0];
								$recBdry_fldid = $fldSeq_nodeNmbr_hash{$hashkey}[2];
								$found = 1;
								last WHLOOP1;
							}
						  }#End if
						}#end foreach
				  }#End else
				  if( $found != 1)
				  {
					$level = $level - 1;
					$i = $i + 1;
				  }
			}#end while
		 }#end else-if fld seq does not end in 1

		 #Calculate relative position
		 $fldRelPos = $nodeNbr - $ffnn_atLvlsNtEq1;
		 #$recBdry_fldid = $nodeNmbr_fldid_hash{$ffnn_atLvlsNtEq1};

	}#End if 

	}#Endif($listId == 0 || $listId == 1)			
	#else if($listId != 0 & $listId != 1)			
	else
	{

		if ( !$listSubRec  )
		{
			my $fldSeq_of_ListId_1;
			if($listId == 2)
			{
				#Calculate RelativePosition wrt to the first list item
				
				$fldRelPos = $nodeNbr - $nodeNmbr_ListId_1;
				$fldRelPos_ListId_2 = $fldRelPos;
				$recBdry_fldid = $fieldDetailsRef->[$fldNbr][5];

			}#end if($listId == 2)
			if($listId > 2)
			{
				#assign the RP and BF values of the first list item
				$fldRelPos = $fldRelPos_ListId_2;	
				$recBdry_fldid = $fieldDetailsRef->[$fldNbr][5];
			}
		}#end if ( !$listSubRec  )
		else #if ( $listSubRec  )
		{
			#Assign previously saved hash values-values corresponding to 
			#listSubRecBdryFldId and listSubRecRelPos

			if( $listId > 1 )
			{
				if ( exists $fldIdHash{$fieldDetailsRef->[$fldNbr][5]} )
				{
					my $hashRef = $fldIdHash{$fieldDetailsRef->[$fldNbr][5]};
					my %recBdryRelPosHash = %$hashRef;

					if ( exists $recBdryRelPosHash{"RecBdry"} )
					{
						$listSubRecBdryFldId = $recBdryRelPosHash{"RecBdry"};
					}

					if ( exists $recBdryRelPosHash{"RelPos"} )
					{
						$listSubRecRelPos = $recBdryRelPosHash{"RelPos"};
	
					}
				}
				else
				{
					$listSubRecBdryFldId = 0;
					$listSubRecRelPos = $HIGHVAL;
				}
			}#end if( $list > 1 )

			if( $listId == 2 )
			{
				my $hashRef = $listIdHash{1};
				my %fldIdNodeNbrHash = %$hashRef;

				if ( $fldIdNodeNbrHash{$fieldDetailsRef->[$fldNbr][5]} )
				{
					$fldRelPos = $nodeNbr - $fldIdNodeNbrHash{$fieldDetailsRef->[$fldNbr][5]} ;

				}
				else
				{
					$fldRelPos = $HIGHVAL;
				}
				
				$recBdry_fldid = $fieldDetailsRef->[$fldNbr][5];

				#Have to save the relpos calculated to assign the same values for the fields
				# in the subrecord with listId>2
				if ( not exists $listId2Hash{$listId} ) 
				{
					$fldId_relPos_hash{$fieldDetailsRef->[$fldNbr][5]} = $fldRelPos;
					$listId2Hash{$listId} = \%fldId_relPos_hash;
				}
				else
				{
					my $hashRef = $listId2Hash{$listId};
					my %fldIdNodeNbrHash = %$hashRef;
					$fldIdNodeNbrHash{$fieldDetailsRef->[$fldNbr][5]} = $fldRelPos;
					$listId2Hash{$listId} = \%fldIdNodeNbrHash;
					
				}

			}#end if( $listId == 2 )
			if ( $listId > 2 )
			{
				if ( exists $listId2Hash{2} )
				{
					my $hashRef = $listId2Hash{2};
					my %fldIdNodeNbrHash = %$hashRef;

					if ( $fldIdNodeNbrHash{$fieldDetailsRef->[$fldNbr][5]} )
					{

						$fldRelPos = $fldIdNodeNbrHash{$fieldDetailsRef->[$fldNbr][5]} ;
					}
					else
					{
						$fldRelPos = $HIGHVAL;
					}

					$recBdry_fldid = $fieldDetailsRef->[$fldNbr][5];
				}

			}#end if ( $listId > 2 )


		}#else #if ( $listSubRec  )	


	}


		# Store the values in the global arrays
		#below saved values are used for moving back safely to the previous state
		push(@subRecFldsCounter, $subRecFldCounter);
		push(@savedFldNbrs, $savedFldNbr);
		push(@listSubRecs, $listSubRec);
		push(@incrementlistIds, $increment_listId);
		push(@fldNbrs, $fldNbr);
		
		#below saved values are used for moving back safely to the previous state
		#and also to be stored in the database
		push(@fldIds, $fldId);
		push(@fldListId, $listId);
		push(@fldDepths, $depth);
		push(@fldTagSeq, $tagSeq);
		push(@fldRelPos, $fldRelPos);
		push(@fanout, $fanout);
		push(@treeLevel, $treeLevel); 
		push(@recBdry_fldid, $recBdry_fldid);
		push(@listSubrecRelPos, $listSubRecRelPos);
		push(@listSubRecBdry_fldid, $listSubRecBdryFldId);
		push(@fldKeywords, $fldKeyword);
		push(@fldOmitwords, $fldOmitword);
		push(@fldBeginsWith, $fldBeginsWith);
		push(@fldEndsWith, $fldEndsWith);
		push(@fldPreceededBy, $fldPreceededBy);
		push(@fldFollowedBy, $fldFollowedBy);
		push(@fldValues, $fldValue);
		
		print("\n Values learnt:");
		print("\n FldId:  $fldId");
		print("\n ListId: $listId");
		print("\n Depths: $depth");
		print("\n TagSeq: $tagSeq");
		print("\n RelPos: $fldRelPos");
		print("\n Fanout: $fanout");
		print("\n TreeLevel: $treeLevel"); 
		print("\n RecBdry_fldid: $recBdry_fldid");
		print("\n listSubrecRelPos: $listSubRecRelPos");
		print("\n listSubRecBdry_fldid: $listSubRecBdryFldId");
		print("\n fldKeywords: $fldKeyword");
		print("\n fldOmitwords: $fldOmitword");
		print("\n fldBeginsWith: $fldBeginsWith");
		print("\n fldEndsWith: $fldEndsWith");
		print("\n fldPreceededBy: $fldPreceededBy");
		print("\n fldFollowedBy: $fldFollowedBy");
		print("\n fldValues: $fldValue");
		
   }#if ($button ne "Skip")

	# Increment the fldNbr counter to move to the next field
	#do not increment field number for simple list items, unless button "DONE" has been clicked
	if( $listId == 0 ||  $doneListItems == 1 || $listSubRec == 1)
	{
		$fldNbr++;
	}
   	
	
	# Reset the counters, empty arrays and insert the values in to the database, if all fields have been filled 
	#In case of list of subrecords, increment the record number only when "Done" is clicked
	if ( !$listSubRec  || $doneListItems )
	{
		if ($fldNbr > $fieldDetailsCount)
		{
			$recordNbr++;
			$fldNbr = 0;

			# Display appropriate message on the status bar
			$status->configure(-text=> "Learning Process (Inserting the sample record)...");

			print("\n Values for all the fields in the record learnt");
			print("\n Inserting them into databse");
			&dbInsertFldValues($dbh, $siteSelected, \@fldIds, \@fldListId, \@fldDepths, \@fldTagSeq,
			                   \@fanout, \@treeLevel, \@fldRelPos, \@recBdry_fldid, 
						\@listSubrecRelPos, \@listSubRecBdry_fldid, \@fldKeywords, 
						\@fldOmitwords, \@fldValues,
						\@fldBeginsWith, \@fldEndsWith, \@fldPreceededBy, \@fldFollowedBy);

			# Display appropriate message on the status bar
			$status->configure(-text=> "Done...");

			undef @fldIds;
			undef @fldNbrs;
			undef @listSubrecRelPos;
			undef @listSubRecBdry_fldid;
			undef @fldListId;
			undef @fldDepths;
			undef @fldTagSeq;
			undef @fldRelPos;
			undef @fanout;
			undef @treeLevel;
			undef @recBdry_fldid;
			undef @fldKeywords;
			undef @fldOmitwords;
			undef @fldBeginsWith;
			undef @fldEndsWith;
			undef @fldPreceededBy;
			undef @fldFollowedBy;
			undef @fldValues;
			undef @incrementlistIds;
			undef @listSubRecs;
			undef @savedFldNbrs;
			undef @subRecFldsCounter;
			undef %fldSeq_nodeNmbr_hash;
			undef $ffnn_atLevel1;
			undef %fldIdHash;
			undef %listIdHash;
			undef %listId2Hash;
			undef %fldId_nodeNbr_hash;
			undef %fldId_relPos_hash;

			# Display appropriate message on the status bar
			$status->configure(-text=> "Learning Process (Formulating Rules)...");

			print("\n Calculating rules for the fields:");
			# Since a record has been shown, call function to derive values for the fields
			&dbDeriveParams($dbh, $siteSelected);

			# Display appropriate message on the status bar
			$status->configure(-text=> "Done...");
		}#end if
	 }#end if
    
    
       #Reset values for a new list item
       if( $nextListItem )
       {
       		$subRecFldCounter = 0;
       }
       
       #reset values if the trainer clicked the "DONE" button
       if( $doneListItems == 1)
       {
    		$doneListItems = 0;
    	    	$listId = 0;
    	    	$copyFldNbr = 0;
    	    	
    	    	if( $listSubRec )
		{
			$listSubRec = 0;
		}
	}
	
	#Reset other values
	$fldRelPos = 0;
	$recBdry_fldid = 0;
	
	# Display appropriate message on the status bar
	$status->configure(-text=> "Learning Process Contd...");

    	$skip = 0;
    	
    	#call sub-routine to dispaly the appropriate next field details in the frame
    	#and to enable/disable the buttons on the frame accordingly
	&setFldName;

	# Clear the current entries
	$len = length $lfNodeNbr->get;
	$len++;
	$lfNodeNbr->delete(0, $len);

	$len = length $lfFldValue->get;
	$len++;
	$lfFldValue->delete(0, $len);

	$len = length $lfFldKeyword->get;
	$len++;
	$lfFldKeyword->delete(0, $len);

	$len = length $lfFldOmitword->get;
	$len++;
	$lfFldOmitword->delete(0, $len);
	
	$len = length $lfFldBeginsWith->get;
	$len++;
	$lfFldBeginsWith->delete(0, $len);
	
	$len = length $lfFldEndsWith->get;
	$len++;
	$lfFldEndsWith->delete(0, $len);
	
	$len = length $lfFldPreceededBy->get;
	$len++;
	$lfFldPreceededBy->delete(0, $len);
	
	$len = length $lfFldFollowedBy->get;
	$len++;
	$lfFldFollowedBy->delete(0, $len);
	
	#set focus(cursor) to nodeNumber field
	$lfNodeNbr->focus;
}

#Routine invoked when the trainer clicks "NEXT LIST ITEM" button
sub learnNextListItem{
my $button;
my $done = 0;
my $nodeNbr;
my $fldValue;
my $text;

		#get the values	
		$nodeNbr = $lfNodeNbr->get;
		$fldValue = $lfFldValue->get;
		
		#if the warning frame when the trainer doesn't enter anything has not been previously displayed
		#display the warning
		if ( (!$skip) and (length $fldValue == 0 or length $nodeNbr == 0) ) 	
		{
			$text = "Do you want to skip this field?";
			do {    
				$button = showDlgPrompt($text);
				if ($button eq "Skip")
				{

					$skip = 1;
					#if the trainer chosses to skip, return if its the first field
					if ( $fldNbr == 0 )
					{
						return;
					}
					#if the trainer chosses to skip and if its not the first field
					#make necessary changes to move to the next list item
					else
					{
						#set the variable to indicate the end of the current list item
						$nextListItem = 1;
						
						#in case of list of sub-records, set the variable to start with
						#the first saved field number of this sub-record						
						if ( $listSubRec )
						{
							$copyFldNbr = 1;
						}

						#increment the list id, in case of simple lists
						if( !$listSubRec && !$doneListItems)
						{
							$listId++;
						}
						
						#invoke sub-routine to learn next field
						learnNextField();
						
						#reset values
						$increment_listId = 0;
						$nextListItem = 0;
						$listSubRecBdryFldId_nodeNbr = 0;
						
					}#end else if ($fldNbr != 0 )
				}#end if ($button eq "Skip")

				$done = 1;
				return if ($button eq "Cancel")
			    } until $done;
		}
		else#if the user entered values
		{
			#make necessary changes to move to the next list item
			#set the variable to indicate the end of the current list item
			$nextListItem = 1;

			#in case of list of sub-records, set the variable to start with
			#the first saved field number of this sub-record		
			if ( $listSubRec )
			{
				$copyFldNbr = 1;
			}

			#increment the list id for the next list item, in case of simple lists
			if( !$listSubRec && !$doneListItems)
			{
				$listId++;
			}
			
			#invoke sub-routine to learn next field
			learnNextField();
			
			#reset values
			$increment_listId = 0;
			$nextListItem = 0;
			$listSubRecBdryFldId_nodeNbr = 0;
		}

}#end  sub nextListItem

#Routine invoked when the trainer clicks the "DONE" button
sub doneListItem{
my $button;
my $done = 0;
my $nodeNbr;
my $fldValue;
my $text;
	
	
	$skip = 0;
	
	#get the values
	$nodeNbr = $lfNodeNbr->get;
	$fldValue = $lfFldValue->get;

	
	#in case of list of sub-recordsor simple lists, if the trainer cliks "DONE" after the first list item,
	#display a warning that he did not provide sample values for the second list items
	if( ( ($listSubRec) && ( $listId == 0 || $listId == 1) ) || ( (!($listSubRec)) && ($listId == 0) ) )
	{
		# If nothing is entered, display warning
		if (length $fldValue == 0 or length $nodeNbr == 0) 	
		{
			$text = "Do you want to skip this field and skip entering all values for second list items?";
			do {    
					$button = showDlgPrompt($text);
					if ($button eq "Skip")
					{
						$skip = 1;
						$doneListItems = 1;
						learnNextListItem();
						enableDisbaleButtons('normal', 'disabled', 'disabled');
					}
					$done = 1;
					return if ($button eq "Cancel")
			    } until $done;
			}
			else
			{
				$text = "Do you want to skip the second list item?";
				
			do {    
				$button = showDlgPrompt($text);
				if ($button eq "Skip")
				{
					#set value indicating that the warning form has been displayed
					$skip = 2;
					
					#set the value for this variable to indicate that the trainer is done
					#providing sample values for the current list
					$doneListItems = 1;
					
					#increment the list id for the current list item, only in case of simple lists,
					#as it has not been incremented previously
					if (!($listSubRec))
					{
						$listId++;
					}
					
					#invoke routine to learn the list item
					learnNextListItem();
					
					#enable appropriate buttons
					enableDisbaleButtons('normal', 'disabled', 'disabled');
					$done = 1;
				 }
				if ($button eq "Cancel")
				{
				      #user chose to continue providing sample values for this list
					learnNextListItem();
					$done = 1;
				}
			   } until $done;
		 	}#end else
		}#End if( $listId == 0 || $listId == 1 )
		#if the current list item is not the first, display different warning and take different actions
		else #if( $listId > 1 )
		{
		
			#If nothing is entered, display warning
			if (length $fldValue == 0 or length $nodeNbr == 0) 	
			{
				$text = "Do you want to skip this field?";
				do {    
					$button = showDlgPrompt($text);
					if ($button eq "Skip")
					{
						#set value indicating that the warning form has been displayed
						$skip = 1;
						
						#set the value for this variable to indicate that the trainer is done
						#providing sample values for the current list
						$doneListItems = 1;
						
						#increment the list id for the current list item, only in case of simple lists,
						#as it has not been incremented previously
						if (!($listSubRec))
						{
							$listId++;
						}
						
						#invoke routine to learn the list item
						learnNextListItem();
						
						#enable appropriate buttons
						enableDisbaleButtons('normal', 'disabled', 'disabled');
					}
						$done = 1;
					return if ($button eq "Cancel")
				    } until $done;
			}
			else
			{
				#set the value for this variable to indicate that the trainer is done
				#providing sample values for the current list
				$doneListItems = 1;
				
				#increment the list id for the current list item, only in case of simple lists,
				#as it has not been incremented previously
				if (!($listSubRec))
				{
					$listId++;
				}
				
				#invoke routine to learn the list item
				learnNextListItem();
				
				#enable appropriate buttons
				enableDisbaleButtons('normal', 'disabled', 'disabled');
			 }
		}#end else if( $listId > 1 )      
		
}#End sub doneListItem()


#subroutine to show the skip/continue window
sub showDlgPrompt{
my ($text) = @_;
my $dlgPromptSkipList;
my $frmPromptSkipList;
my $button;

	$dlgPromptSkipList = $mainwin->DialogBox(-title=> "Warning!!",-buttons=>[ "Skip", "Cancel" ]);
	$frmPromptSkipList = $dlgPromptSkipList->Frame->pack(-side=>"top", -fill=>'x');
	$frmPromptSkipList->Label(-text => "$text")->pack(-side=>"left", -padx=>5, -pady=>5);
	$button = $dlgPromptSkipList->Show;

	return $button;
}#end showDlgPrompt


# SubRoutine to enable/disable buttons
sub enableDisbaleButtons {

my ($nextFieldState, $nextListItemState, $doneState) = @_;

	$lfBtnNextField->configure(-state=>$nextFieldState);
	$lfBtnNextListItem->configure(-state=>$nextListItemState);
	$lfBtnDone->configure(-state=>$doneState);
	
}#end enableDisbaleButtons


# Routine invoked when the trainer clicks "PREV" button 
sub learnPrev {
my $len;

	print("\n Moving back one step");	
	if( $listSubRec )
	{
		
		if ( ($#fldNbrs + 1 ) > 0 )
		{
		  #pop the saved values, denoting previous state from the arrays
			$fldNbr = pop @fldNbrs;
			$listId = pop @fldListId;
			$increment_listId = pop @incrementlistIds;
			$listSubRec = pop @listSubRecs;
			$savedFldNbr = pop @savedFldNbrs;
			$subRecFldCounter = pop @subRecFldsCounter;
			
			#decrement the sub-record field number
			if ( $subRecFldCounter > 0 )
			{
				$subRecFldCounter--;
			}
			
			#delete the saved values
			if  (exists $fldIdHash{$fieldDetailsRef->[$fldNbr][5]} )
			{
				delete $fldIdHash{$fieldDetailsRef->[$fldNbr][5]};
			}
			
			
			if ( exists $listIdHash{$listId} )
			{
				my $hash1Ref = $listIdHash{$listId};
				my %fldIdNodeNbr1Hash = %$hash1Ref;
			
				if ( exists $fldIdNodeNbr1Hash{$fieldDetailsRef->[$fldNbr][5]} )
				{
					delete $fldIdNodeNbr1Hash{$fieldDetailsRef->[$fldNbr][5]};
					$listIdHash{$listId} = \%fldIdNodeNbr1Hash;
				}
			}
			
			if ( exists $listId2Hash{$listId} )
			{
				my $hash2Ref = $listId2Hash{$listId};
				my %fldIdNodeNbr2Hash = %$hash2Ref;
				
				if ( exists $fldIdNodeNbr2Hash{$fieldDetailsRef->[$fldNbr][5]} )
				{
					delete $fldIdNodeNbr2Hash{$fieldDetailsRef->[$fldNbr][5]};
					$listId2Hash{$listId} = \%fldIdNodeNbr2Hash;
				}
			}
			
			#reset values
			$fieldDetailsRef->[$fldNbr][3] =~ /^\d{1}\.\d*(\d)$/;
			if ( $1 == 1 )
			{
				$listSubRecBdryFldId_nodeNbr = 0;
				$listSubRecBdryFldId = 0;
							
			}
			
		}#if ( ($#fldNbrs + 1 ) > 0 )
	}#if( $listSubRec )
	
	else
	{
		
		my $done = 0;
		my $subRecFlg;

		# If already on the first field, return
		if ( $fldNbr == 0 )
		{
			return;
		}

		# Decrement the values
		if ( $listId == 0 )
		{
		   $fldNbr--;
		}

		if( $listId > 0 )
		{
		  $listId--;
		}

		#get the correct field number, if the previous field is sub-record
		if( $fldNbr > 0 )
		{
			while ( $done == 0 )
			{
				$subRecFlg = $fieldDetailsRef->[$fldNbr][2];
				if ( $subRecFlg eq 'Y' )
				{
					$fldNbr--;
					if( $fldNbr == 0 )
					{
						$done = 1;
					}
				}
				else
				{
					$done = 1;
				}
			}
		}

		
		#get the correct field number, if the previous field is sub-record
		$done = 0;
		if ($fldNbr == 0)
		{
			while ( $done == 0 )
			{
				$subRecFlg = $fieldDetailsRef->[$fldNbr][2];
				if ( $subRecFlg eq 'Y' )
				{
					$fldNbr++;
				}
				else
				{
					$done = 1;
				}

			}

		}
		
		#pop out previous values
		 pop @fldNbrs;
		 pop @fldListId;
		 $increment_listId = pop @incrementlistIds;
		 $listSubRec = pop @listSubRecs;
		 $savedFldNbr = pop @savedFldNbrs;
		 $subRecFldCounter = pop @subRecFldsCounter;
	   }#end else if (!listSubRec)
	   
	# Pop the values from the global array
	pop @fldIds;
	pop @fldDepths;
	pop @fldTagSeq;
	pop @fanout;
	pop @treeLevel;
	pop @fldRelPos;
	pop @recBdry_fldid;
	pop @fldKeywords;
	pop @fldOmitwords;
	pop @fldBeginsWith;
	pop @fldEndsWith;
	pop @fldPreceededBy;
	pop @fldFollowedBy;
	pop @fldValues;
	pop @listSubrecRelPos;
	pop @listSubRecBdry_fldid;

	
	# Clear the current entries
	$len = length $lfNodeNbr->get;
	$len++;
	$lfNodeNbr->delete(0, $len);

	$len = length $lfFldValue->get;
	$len++;
	$lfFldValue->delete(0, $len);

	$len = length $lfFldKeyword->get;
	$len++;
	$lfFldKeyword->delete(0, $len);

	$len = length $lfFldOmitword->get;
	$len++;
	$lfFldOmitword->delete(0, $len);

	#call sub-routine to display proper values in the frame
	#and to enable proper buttons
    	&setFldName();
}

# Sub routine that displays the About Dialog
sub aboutMenu {
	$dlgAboutMenu->Show;
}


# Open the file selected and display in the text area
sub openFile {
my $value;
my $done = 0;
my $line;
my $nodeNbr = 0;
my $file;

	# Free up the previous Tree and List structure
	if (defined $tree)
	{
		$tree = $tree->delete;
	}
	undef %htmlList;
	
	#delete any previous entry
	$txtFileName->delete(0, 'end');

	# Display appropriate message on the status bar
	$status->configure(-text=> "Opening File ...");

	do {    
		 $value = $dlgOpenFile->Show;
		 if ($value eq "OK")
		 {
		     #get the file name
		     $file = $txtFileName->get;
			
			print("\nFile Selected: $file");					
			# Check to see if the file name was entered
			if ( length $file > 0)
			{

				# Display only text in the text area
				$tree = &retHtmlTree($file);
				
				print("\nTree Created");
				#remove text formatting tags from the tree
				$tree = &removeTextFormatingTags($tree);
				
				#$tree->dump();
								
				# Get the nodes of HTML tree in a list 
				%htmlList = &retHtmlListFromTree($tree);
				
				#display the text nodes in the text area
				$tree->traverse(sub { 
							my ($node, $start, $depth ) = @_; 
							
							$nodeNbr++; 
							if (ref $node) 
							{
								print "";
								
							}
							else
							{
								# Ignore line with whitespaces only
								if ($node !~ /^\s+$/)
								{
									print FILE "$nodeNbr " . " " x $depth . qq{:$node:\n}; 
							        }
							}
						},0);
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


# Routine to prompt for files to be opened
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
        if (defined $file and $file ne '')
        {
		$fileName->delete(0, 'end');
		$fileName->insert(0, $file);
		$fileName->xview('end');

		# Open the file 
		$fileOpened = IO::File->new($file)
						or die "Could not open File \n";
	}
}

$dbh->disconnect;
