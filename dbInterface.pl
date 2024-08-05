# Description : This module contains subroutines that is used by
#               the learner and extractor to interact with the database

use strict;
use Mysql;

#my $dbh;				# Database Handle
#my $dbname="thesis";	# The database to connect to 
#my $user="root";		# The user name for the database

#$dbh = DBI->connect("DBI:mysql:$dbname", $user)
#					or die "Can't connect: " . DBI->errstr;

#&dbDeriveParams($dbh, "VARSITYBOOKS");

#$dbh->disconnect;


# Gets the site id of a given site
sub dbGetSiteId {
	my ($dbh, $siteName) = @_;
	my $selH;
	my $sqlStr;
	my $siteId;

	# Make the sql string 
	$sqlStr="select SITEID from SITES where SITENAME = '$siteName'\n";

	print "\n";
	print $sqlStr;

	# Prepare the query
	$selH = $dbh->prepare($sqlStr)
						or die "Couldn't prepare: " . $dbh->errstr . "\n";

	# Execute the query
	$selH->execute
			or die "Couldn't execute: " . $selH->errstr;
	
	# Fetch the value 
	$siteId = $selH->fetchrow; 

	# Close the handle
	$selH->finish;

	# Return the array
	return $siteId; 
}

# Gets the field sequence of a given field
sub dbGetParentFldSeq {
	my ($dbh, $pId) = @_;
	my $selH;
	my $sqlStr;
	my $fldSeq;

	# Make the sql string 
	$sqlStr="select FLDSEQ from SITEFIELDS where FLDID = $pId\n";

	print "\n";
	print $sqlStr;

	# Prepare the query
	$selH = $dbh->prepare($sqlStr)
						or die "Couldn't prepare: " . $dbh->errstr . "\n";

	# Execute the query
	$selH->execute
			or die "Couldn't execute: " . $selH->errstr;
	
	# Fetch the value 
	$fldSeq = $selH->fetchrow; 

	# Close the handle
	$selH->finish;

	# Return the array
	return $fldSeq; 
}


# Gets the template id of a given template
sub dbGetTemplateId {
	my ($dbh, $templateName) = @_;
	my $selH;
	my $sqlStr;
	my $templateId;

	# Make the sql string 
	$sqlStr="select TEMPLATEID from TEMPLATES where TEMPLATENAME = '$templateName'\n";

	print "\n";
	print $sqlStr;

	# Prepare the query
	$selH = $dbh->prepare($sqlStr)
						or die "Couldn't prepare: " . $dbh->errstr . "\n";

	# Execute the query
	$selH->execute
			or die "Couldn't execute: " . $selH->errstr;
	
	# Fetch the value 
	$templateId = $selH->fetchrow; 

	# Close the handle
	$selH->finish;

	# Return the array
	return $templateId; 
}


# retrieve rows with subrecord flag set
sub dbRetriveSubRecRows{
my ($dbh, $siteName, $levelId) = @_;
my $siteId;
my $sqlStr;
my $selH;
my $allrows;
my @fldid;
my @fldname;
	 
	 
	# get siteId
	$siteId = &dbGetSiteId($dbh, $siteName);
	  
	# Make the sql string 
	$sqlStr = "select FLDID, FLDNAME from SITEFIELDS \n";
	$sqlStr = $sqlStr." where SITEID = $siteId \n";
	$sqlStr = $sqlStr." and LEVELID = $levelId \n ";
	$sqlStr = $sqlStr." and SUBRECORD_FLG = 'Y' \n";

	print "\n";
	print $sqlStr;

	# Prepare the query
	$selH = $dbh->prepare($sqlStr)
						or die "Couldn't prepare: " . $dbh->errstr . "\n";

	# Execute the query
	$selH->execute
			or die "Couldn't execute: " . $selH->errstr;

	# Fetch all rows as a reference to an array of arrays of references to each row
	$allrows = $selH->fetchall_arrayref
		  or die "$selH->errstr\n";


	# Close the handle
	$selH->finish;

	# Return the array
    	return  $allrows; 
}
	
	
	  

# Creates a new site in the database
sub dbSiteCreate {
	my( $dbh, $siteName, $levelId, $parentId, $fldNameRef, $fldTypeRef, $fldMandatoryFlgRef, $fldListFlgRef, $fldSubRecordFlgRef) = @_;
	my $insH;
	my $selH;
	my @fldName = @$fldNameRef;
	my @fldType = @$fldTypeRef;
	my @fldMandatoryFlg = @$fldMandatoryFlgRef;
	my @fldListFlg = @$fldListFlgRef; 
	my @fldSubRecFlg = @$fldSubRecordFlgRef;
	my $sqlStr;
	my $siteId;
	my $totFlds;
	my $i;
	my $j;
	my $parentFldSeq;
	my $fldSeq;
	

 	if($levelId == 1)
 	{
		# Make the sql to insert into the SITES table 
		$sqlStr="insert SITES (SITENAME) values ('$siteName')\n";
	
		print "\n";
		print $sqlStr;

		# Prepare the sql 
		$insH = $dbh->prepare($sqlStr)
						or die "Couldn't prepare: " . $dbh->errstr . "\n";

		# Execute the query to create the site 
		$insH->execute
			or die "Couldn't execute: " . $insH->errstr;
	
		# Close the handle
		$insH->finish;

		# Get the SITEID assigned to this site from the site table
		$siteId = &dbGetSiteId($dbh, $siteName);
	}

  	# Get the SITEID assigned to this site from the site table
	$siteId=&dbGetSiteId($dbh, $siteName);

	# Insert the fields defined for this site

	# Get the total number of fields
	$totFlds = $#fldName;
	
	# Loop for each field and insert into SITEFIELDS table
	for $i (0 .. $totFlds)
	{
	
		# create FLDSEQ for the field
		if($levelId == 1) 
		{
	   		$fldSeq = $i + 1;
	   	}
	 	elsif ($levelId == 2)
	 	{
	     		$parentFldSeq = &dbGetParentFldSeq($dbh, $parentId);
		        $j = "0." . ($i + 1);
			 $fldSeq = $parentFldSeq + $j;
		}
	  	else
	  	{
	     		$parentFldSeq = &dbGetParentFldSeq($dbh, $parentId);
		        $j = $i + 1;
			$fldSeq =  $parentFldSeq . $j;
		}
	   
	     	   
		# Prepare the query
		$sqlStr="insert SITEFIELDS (SITEID, PARENTID,LEVELID, FLDSEQ, FLDNAME, FLDTYPE, \n";
		$sqlStr=$sqlStr."MANDATORY_FLG, LIST_FLG, SUBRECORD_FLG) values (\n";
		$sqlStr=$sqlStr.$siteId.",". $parentId. "," . $levelId. ",". $fldSeq. ",'".$fldName[$i]."',\n'";
		$sqlStr=$sqlStr.$fldType[$i]."','".$fldMandatoryFlg[$i]."',\n'";
		$sqlStr=$sqlStr.$fldListFlg[$i]."','".$fldSubRecFlg[$i]."')\n";
		

		print "\n";
		print $sqlStr;

		$insH = $dbh->prepare($sqlStr)
							or die "Couldn't prepare: " . $dbh->errstr . "\n";

		# Execute the query
		$insH->execute
				or die "Couldn't execute: " . $insH->errstr;

		# Close the handle
		$insH->finish;
		
		$fldSeq += 1;
	}
}


# Creates a new template in the database
sub dbtemplateCreate {
	my($dbh, $templateName, $fldNameRef) = @_;
	my $insH;
	my $selH;
	my @fldName=@$fldNameRef;
	my $sqlStr;
	my $templateId;
	my $totFlds;
	my $i;

	# Make the sql to insert into the TEMPLATES table 
	$sqlStr="insert TEMPLATES (TEMPLATENAME) values ('$templateName')\n";
	
	print "\n";
	print $sqlStr;

	# Prepare the sql 
	$insH = $dbh->prepare($sqlStr)
						or die "Couldn't prepare: " . $dbh->errstr . "\n";

	# Execute the query to create the template 
	$insH->execute
			or die "Couldn't execute: " . $insH->errstr;

	# Close the handle
	$insH->finish;

	# Get the TEMPLATEID assigned to this template from the TEMPLATE table
	$templateId=&dbGetTemplateId($dbh, $templateName);

	print "\n";
	print "Id assigned to $templateName template = $templateId\n";

	# Insert the fields defined for this template

	# Get the total number of fields
	$totFlds = $#fldName;

	# Loop for each field and insert into TEMPLATEFIELDS table
	for $i (0 .. $totFlds) {

		# Prepare the query
		$sqlStr="insert TEMPLATEFIELDS (TEMPLATEID, TEMPLATEFLDNAME) \n";
		$sqlStr=$sqlStr."values ($templateId, '".$fldName[$i]."')\n";

		print "\n";
		print $sqlStr;

		$insH = $dbh->prepare($sqlStr)
							or die "Couldn't prepare: " . $dbh->errstr . "\n";

		# Execute the query
		$insH->execute
				or die "Couldn't execute: " . $insH->errstr;

		# Close the handle
		$insH->finish;
	}
}

# Get the names of the field that are not sub-records for a given site
sub dbGetFldNames {
my ($dbh, $siteName) = @_;
my $getFldH;
my $sqlStr;
my $name;
my @fldNames;

	# Create the sql string 
	$sqlStr="select FLDNAME \n";
	$sqlStr=$sqlStr."from SITES S, SITEFIELDS F \n";
	$sqlStr=$sqlStr."where S.SITEID = F.SITEID \n";
	$sqlStr=$sqlStr."and S.SITENAME = '$siteName' and SUBRECORD_FLG = 'N' order by F.FLDSEQ\n";

	print "\n";
	print $sqlStr;

	# Prepare the query
	$getFldH = $dbh->prepare($sqlStr)
						or die "Couldn't prepare: " . $dbh->errstr . "\n";

	# Execute the query
	$getFldH->execute
			or die "Couldn't execute: " . $getFldH->errstr;
	
	# Fetch each row and put it in an array
	while ($name = $getFldH->fetchrow) 
	{
		push (@fldNames, $name);
	}

	# Close the handle
	$getFldH->finish;

	# Return the array, every element is field name 
	return @fldNames;
}



# Subroutine to get the lowest fldId at a given level
sub dbGetLowFldId{
my ($dbh, $siteName, $levelId) = @_;
my $siteId;
my $sqlStr;
my $selH;
my $fldId;
	   
	# get siteId
	$siteId = &dbGetSiteId($dbh, $siteName);
	  
	 
	# Make the sql string 
	$sqlStr = "select min(FLDID) from SITEFIELDS \n";
	$sqlStr = $sqlStr." where SITEID = $siteId \n";
	$sqlStr = $sqlStr." and LEVELID = $levelId \n ";
	$sqlStr = $sqlStr." and SUBRECORD_FLG = 'N' \n";

	print "\n";
	print $sqlStr;

	# Prepare the query
	$selH = $dbh->prepare($sqlStr)
						or die "Couldn't prepare: " . $dbh->errstr . "\n";

	# Execute the query
	$selH->execute
			or die "Couldn't execute: " . $selH->errstr;

    	# Fetch the value 
	$fldId = $selH->fetchrow; 

	# Close the handle
	$selH->finish;

	# Return the array
	return $fldId; 
	   	
}

#Subroutine to get the parent Id of a given field
sub dbGetParentId{
my ($dbh, $siteName, $fldId) = @_;
my $siteId;
my $sqlStr;
my $selH;
my $parentId;
	 	   
	# get siteId
	$siteId = &dbGetSiteId($dbh, $siteName);
	  
	 	 
	# Make the sql string 
	$sqlStr = "select PARENTID from SITEFIELDS \n";
	$sqlStr = $sqlStr." where SITEID = $siteId \n";
	$sqlStr = $sqlStr." and FLDID = $fldId \n ";

	print "\n";
	print $sqlStr;

	# Prepare the query
	$selH = $dbh->prepare($sqlStr)
						or die "Couldn't prepare: " . $dbh->errstr . "\n";

	# Execute the query
	$selH->execute
			or die "Couldn't execute: " . $selH->errstr;

    	# Fetch the value 
	$parentId = $selH->fetchrow; 

	# Close the handle
	$selH->finish;

	# Return the array
	return $parentId; 

}

#Subroutine to get the name of given field
sub dbGetFldName{
my ($dbh, $siteName, $fldId) = @_;
my $siteId;
my $sqlStr;
my $selH;
my $fldName;
	 	   
	# get siteId
	$siteId = &dbGetSiteId($dbh, $siteName);
	  	  
	 	 
	# Make the sql string 
	$sqlStr = "select FLDNAME from SITEFIELDS \n";
	$sqlStr = $sqlStr." where SITEID = $siteId \n";
	$sqlStr = $sqlStr." and FLDID = $fldId \n ";

	print "\n";
	print $sqlStr;

	# Prepare the query
	$selH = $dbh->prepare($sqlStr)
						or die "Couldn't prepare: " . $dbh->errstr . "\n";

	# Execute the query
	$selH->execute
			or die "Couldn't execute: " . $selH->errstr;

    	# Fetch the value 
	$fldName = $selH->fetchrow; 

	# Close the handle
	$selH->finish;

	# Return the array
	return $fldName; 
	   	
}

# Subroutine to get field ids of all the fields with a particular list id
sub dbGetFldId{
my ($dbh, $siteName, $listId) = @_;
my $siteId;
my $sqlStr;
my $selH;
my $fldId;
	   
	# get siteId
	$siteId = &dbGetSiteId($dbh, $siteName);


	# Make the sql string 
	$sqlStr = "select FLDID from SAMPLEVALUES \n";
	$sqlStr = $sqlStr." where SITEID = $siteId \n";
	$sqlStr = $sqlStr." and LISTID = $listId \n ";

	print "\n";
	print $sqlStr;

	# Prepare the query
	$selH = $dbh->prepare($sqlStr)
						or die "Couldn't prepare: " . $dbh->errstr . "\n";

	# Execute the query
	$selH->execute
			or die "Couldn't execute: " . $selH->errstr;

    	# Fetch the value 
	$fldId = $selH->fetchrow; 

	# Close the handle
	$selH->finish;

	# Return the array
	return $fldId; 
	   	
}

# Subroutine to get the field sequence of a given field 
sub dbGetFldSeq{
      my ($dbh, $siteName, $fldId) = @_;
	  my $siteId;
	  my $sqlStr;
	  my $selH;
	  my $fldSeq;
	   
	# get siteId
	$siteId = &dbGetSiteId($dbh, $siteName);
	  
	 
	# Make the sql string 
	$sqlStr = "select FLDSEQ from SITEFIELDS \n";
	$sqlStr = $sqlStr." where SITEID = $siteId \n";
	$sqlStr = $sqlStr." and FLDID = $fldId \n ";

	print "\n";
	print $sqlStr;

	# Prepare the query
	$selH = $dbh->prepare($sqlStr)
						or die "Couldn't prepare: " . $dbh->errstr . "\n";

	# Execute the query
	$selH->execute
			or die "Couldn't execute: " . $selH->errstr;

    	# Fetch the value 
	$fldSeq = $selH->fetchrow; 

	# Close the handle
	$selH->finish;

	# Return the array
	return $fldSeq; 
	   	
}

# Subroutine to get the relative position of all the fields with the same list id
sub dbGetRelPos{
my ($dbh, $siteName, $listId) = @_;
my $siteId;
my $sqlStr;
my $selH;
my $relPos;
	   
	# get siteId
	$siteId = &dbGetSiteId($dbh, $siteName);
	  
	 
	# Make the sql string 
	$sqlStr = "select RELPOS from SAMPLEVALUES \n";
	$sqlStr = $sqlStr." where SITEID = $siteId \n";
	$sqlStr = $sqlStr." and LISTID = $listId \n ";

	print "\n";
	print $sqlStr;

	# Prepare the query
	$selH = $dbh->prepare($sqlStr)
						or die "Couldn't prepare: " . $dbh->errstr . "\n";

	# Execute the query
	$selH->execute
			or die "Couldn't execute: " . $selH->errstr;

    	# Fetch the value 
	$relPos = $selH->fetchrow; 

	# Close the handle
	$selH->finish;

	# Return the array
	return $relPos; 
	   	
}

# Subroutine to get the boundary field ids of all the fields with the same list id
sub dbGetRecBdryFldId{
my ($dbh, $siteName, $listId) = @_;
my $siteId;
my $sqlStr;
my $selH;
my $recBdryFldId;
	   
	# get siteId
	$siteId = &dbGetSiteId($dbh, $siteName);
	  
	 
	# Make the sql string 
	$sqlStr = "select RECBDRYFLDID from SAMPLEVALUES \n";
	$sqlStr = $sqlStr." where SITEID = $siteId \n";
	$sqlStr = $sqlStr." and LISTID = $listId \n ";

	print "\n";
	print $sqlStr;

	# Prepare the query
	$selH = $dbh->prepare($sqlStr)
						or die "Couldn't prepare: " . $dbh->errstr . "\n";

	# Execute the query
	$selH->execute
			or die "Couldn't execute: " . $selH->errstr;

    	# Fetch the value 
	$recBdryFldId = $selH->fetchrow; 

	# Close the handle
	$selH->finish;

	# Return the array
	return $recBdryFldId; 
	   	
}

# Subroutine to get the mandatory field ids of all the fields for a given site
sub dbGetMandatoryFldIds {
my ($dbh, $siteName) = @_;
my $selH;
my $sqlStr;
my $fldId;
my @fldIds;

	# Make the sql string 
	$sqlStr="select FLDID \n";
	$sqlStr=$sqlStr."from SITES S, SITEFIELDS F \n";
	$sqlStr=$sqlStr."where S.SITEID = F.SITEID \n";
	$sqlStr=$sqlStr."and S.SITENAME = '$siteName' \n";
	$sqlStr=$sqlStr."and MANDATORY_FLG='Y' and SUBRECORD_FLG='N' order by F.FLDSEQ\n";

	print "\n";
	print $sqlStr;

	# Prepare the query
	$selH = $dbh->prepare($sqlStr)
						or die "Couldn't prepare: " . $dbh->errstr . "\n";

	# Execute the query
	$selH->execute
			or die "Couldn't execute: " . $selH->errstr;
	
	# Fetch the mandatory field names 
	while ($fldId = $selH->fetchrow)
	{
		push (@fldIds, $fldId);
	}

	# Close the handle
	$selH->finish;

	# Return the array
	return @fldIds; 
}


# Gets the field ids for a given site ordered by their field sequences
sub dbGetFldIds {
my ($dbh, $siteName) = @_;
my $selH;
my $sqlStr;
my $fldId;
my @fldIds;

	# Make the sql string 
	$sqlStr="select FLDID \n";
	$sqlStr=$sqlStr."from SITES S, SITEFIELDS F \n";
	$sqlStr=$sqlStr."where S.SITEID = F.SITEID \n";
	$sqlStr=$sqlStr."and S.SITENAME = '$siteName' order by F.FLDSEQ\n";

	print "\n";
	print $sqlStr;

	# Prepare the query
	$selH = $dbh->prepare($sqlStr)
						or die "Couldn't prepare: " . $dbh->errstr . "\n";

	# Execute the query
	$selH->execute
			or die "Couldn't execute: " . $selH->errstr;
	
	# Fetch the field ids 
	while ($fldId = $selH->fetchrow)
	{
		push (@fldIds, $fldId);
	}

	# Close the handle
	$selH->finish;

	# Return the array
	return @fldIds; 
}

# Gets the field ids of fields that are not sub-records for a given site ordered by their field sequences
sub dbGetFldIdsWithValues {
my ($dbh, $siteName) = @_;
my $selH;
my $sqlStr;
my $fldId;
my @fldIds;

	# Make the sql string 
	$sqlStr="select FLDID \n";
	$sqlStr=$sqlStr."from SITES S, SITEFIELDS F \n";
	$sqlStr=$sqlStr."where S.SITEID = F.SITEID \n";
	$sqlStr=$sqlStr."and S.SITENAME = '$siteName' and SUBRECORD_FLG = 'N' order by F.FLDSEQ\n";

	print "\n";
	print $sqlStr;

	# Prepare the query
	$selH = $dbh->prepare($sqlStr)
						or die "Couldn't prepare: " . $dbh->errstr . "\n";

	# Execute the query
	$selH->execute
			or die "Couldn't execute: " . $selH->errstr;
	
	# Fetch the field ids 
	while ($fldId = $selH->fetchrow)
	{
		push (@fldIds, $fldId);
	}

	# Close the handle
	$selH->finish;

	# Return the array
	return @fldIds; 
}

# Gets the list ids of all the fields for a given site
sub dbGetListIds {
my ($dbh, $siteName) = @_;
my $selH;
my $sqlStr;
my $listId;
my @listIds;

	# Make the sql string 
	$sqlStr="select LISTID \n";
	$sqlStr=$sqlStr."from SITES S, SAMPLEVALUES SV \n";
	$sqlStr=$sqlStr."where S.SITEID = SV.SITEID \n";
	$sqlStr=$sqlStr."and S.SITENAME = '$siteName'\n";

	print "\n";
	print $sqlStr;

	# Prepare the query
	$selH = $dbh->prepare($sqlStr)
						or die "Couldn't prepare: " . $dbh->errstr . "\n";

	# Execute the query
	$selH->execute
			or die "Couldn't execute: " . $selH->errstr;
	
	# Fetch the field ids 
	while ($listId = $selH->fetchrow)
	{
		push (@listIds, $listId);
	}

	# Close the handle
	$selH->finish;

	# Return the array
	return @listIds; 
}

# Gets the field ids for a given Template 
sub dbGetTemplateFldIds {
my ($dbh, $templateName) = @_;
my $selH;
my $sqlStr;
my $fldId;
my @fldIds;

	# Make the sql string 
	$sqlStr="select TEMPLATEFLDID \n";
	$sqlStr=$sqlStr."from TEMPLATES T, TEMPLATEFIELDS F \n";
	$sqlStr=$sqlStr."where T.TEMPLATEID = F.TEMPLATEID \n";
	$sqlStr=$sqlStr."and T.TEMPLATENAME = '$templateName' order by F.TEMPLATEFLDID\n";

	print "\n";
	print $sqlStr;

	# Prepare the query
	$selH = $dbh->prepare($sqlStr)
						or die "Couldn't prepare: " . $dbh->errstr . "\n";

	# Execute the query
	$selH->execute
			or die "Couldn't execute: " . $selH->errstr;
	
	# Fetch the field ids 
	while ($fldId = $selH->fetchrow)
	{
		push (@fldIds, $fldId);
	}

	# Close the handle
	$selH->finish;

	# Return the array
	return @fldIds; 
}

# Returns the max record number learnt for a give site 
sub dbGetMaxRecNbr {
my ($dbh, $siteName) = @_;
my $selH;
my $sqlStr;
my $maxRecNbr;

	# Make the sql string 
	$sqlStr="select max(RECNBR) \n";
	$sqlStr=$sqlStr."from SITES S, SAMPLEVALUES SV \n";
	$sqlStr=$sqlStr."where S.SITEID = SV.SITEID \n"; 
	$sqlStr=$sqlStr."and S.SITENAME = '$siteName'\n";

	print "\n";
	print $sqlStr;

	# Prepare the query
	$selH = $dbh->prepare($sqlStr)
						or die "Couldn't prepare: " . $dbh->errstr . "\n";

	# Execute the query
	$selH->execute
			or die "Couldn't execute: " . $selH->errstr;
	
	# Fetch the value 
	$maxRecNbr = $selH->fetchrow; 

	# Close the handle
	$selH->finish;

	# Return the array
	return $maxRecNbr; 
}

# Get names of all the sites in our database
sub dbGetSites {
my ($dbh, $siteName) = @_;
my $selH;
my $sqlStr;
my $name;
my @siteNames;

	# Create the sql string 
	$sqlStr="select SITENAME from SITES\n";

	print "\n";
	print $sqlStr;

	# Prepare the query
	$selH = $dbh->prepare($sqlStr)
						or die "Couldn't prepare: " . $dbh->errstr . "\n";

	# Execute the query
	$selH->execute
			or die "Couldn't execute: " . $selH->errstr;
	
	# Fetch each row and put it in an array
	while ($name = $selH->fetchrow) 
	{
		push (@siteNames, $name);
	}

	# Close the handle
	$selH->finish;

	# Return the array
	return @siteNames;
}

# Get names of all the Templates in our database
sub dbGetTemplates {
my ($dbh, $templateName) = @_;
my $selH;
my $sqlStr;
my $name;
my @templateNames;

	# Create the sql string 
	$sqlStr="select TEMPLATENAME from TEMPLATES\n";

	print "\n";
	print $sqlStr;

	# Prepare the query
	$selH = $dbh->prepare($sqlStr)
						or die "Couldn't prepare: " . $dbh->errstr . "\n";

	# Execute the query
	$selH->execute
			or die "Couldn't execute: " . $selH->errstr;
	
	# Fetch each row and put it in an array
	while ($name = $selH->fetchrow) {
		push (@templateNames, $name);
	}

	# Close the handle
	$selH->finish;

	# Return the array
	return @templateNames;
}

# Get certain details for all the fields for a given site ordered by their field sequences
sub dbGetFldDetails {
my ($dbh, $siteName) = @_;
my $getFldDetails;
my $sqlStr;
#my $name;
my $allrows;

	# Create the sql string 
	$sqlStr = "select FLDNAME, LIST_FLG, SUBRECORD_FLG, FLDSEQ, LEVELID, FLDID \n";
	$sqlStr=$sqlStr."from SITES S, SITEFIELDS F \n";
	$sqlStr=$sqlStr."where S.SITEID = F.SITEID \n";
	$sqlStr=$sqlStr."and S.SITENAME = '$siteName' order by F.FLDSEQ\n";

	print "\n";
	print $sqlStr;

	# Prepare the query
	$getFldDetails = $dbh->prepare($sqlStr)
						or die "Couldn't prepare: " . $dbh->errstr . "\n";

	# Execute the query
	$getFldDetails->execute
			or die "Couldn't execute: " . $getFldDetails->errstr;
	
	# Fetch all rows as a reference to an array of arrays of references to each row
	$allrows = $getFldDetails->fetchall_arrayref
	                  or die "$getFldDetails->errstr\n";

	# Close the handle
	$getFldDetails->finish;

	# Return the array, every element is field name 
	return $allrows;
}

# Get all the distinct ParentdId's for a given site
sub dbGetParentIds {
my ($dbh, $siteName) = @_;
my $getParentID;
my $sqlStr;
my $parentId;
my @ParentID;

	# Create the sql string 
	$sqlStr="select distinct PARENTID \n";
	$sqlStr=$sqlStr."from SITES S, SITEFIELDS F \n";
	$sqlStr=$sqlStr."where S.SITEID = F.SITEID \n";
	$sqlStr=$sqlStr."and S.SITENAME = '$siteName' order by F.LEVELID desc\n";

	print "\n";
	print $sqlStr;

	# Prepare the query
	$getParentID = $dbh->prepare($sqlStr)
						or die "Couldn't prepare: " . $dbh->errstr . "\n";

	# Execute the query
	$getParentID->execute
			or die "Couldn't execute: " . $getParentID->errstr;
	
	# Fetch each row and put it in an array
	while ($parentId = $getParentID->fetchrow) 
	{
		push (@ParentID, $parentId);
	}

	# Close the handle
	$getParentID->finish;

	# Return the array, every element is field name 
	return @ParentID;
}

# get all child names for a given parent, for a given site
sub dbGetChildNames{
      my ($dbh, $siteName, $parentId) = @_;
	  my $siteId;
	  my $sqlStr;
	  my $selH;
	  my $allrows;
	  
	  # get siteId
	  $siteId = &dbGetSiteId($dbh, $siteName);
	  
	  # Make the sql string 
	  	$sqlStr = "select FLDID, FLDNAME, SUBRECORD_FLG, MANDATORY_FLG, LIST_FLG from SITEFIELDS \n";
		$sqlStr = $sqlStr." where SITEID = $siteId and SUBRECORD_FLG = 'N' \n";
		$sqlStr = $sqlStr." and PARENTID = $parentId order by FLDID\n ";
		
		print "\n";
	  	print ("\n$sqlStr");
	  
	  	# Prepare the query
	  	$selH = $dbh->prepare($sqlStr)
	  						or die "Couldn't prepare: " . $dbh->errstr . "\n";
	  
	  	# Execute the query
	  	$selH->execute
	  			or die "Couldn't execute: " . $selH->errstr;
	  	
	  	# Fetch all rows as a reference to an array of arrays of references to each row
		$allrows = $selH->fetchall_arrayref
	                  or die "$selH->errstr\n";
	  
	  
	  	# Close the handle
	  	$selH->finish;
	  
	  	# Return the array
 	    return  $allrows; 
}
# Get all the field names for a given Template
sub dbGetTemplateFldNames {
	my ($dbh, $templateName) = @_;
	my $getFldH;
	my $sqlStr;
	my $name;
	my @fldNames;

	# Create the sql string 
	        $sqlStr="select TEMPLATEFLDNAME \n";
	$sqlStr=$sqlStr."from TEMPLATES T, TEMPLATEFIELDS F \n";
	$sqlStr=$sqlStr."where T.TEMPLATEID = F.TEMPLATEID \n";
	$sqlStr=$sqlStr."and T.TEMPLATENAME = '$templateName' order by F.TEMPLATEFLDID\n";

	print "\n";
	print $sqlStr;

	# Prepare the query
	$getFldH = $dbh->prepare($sqlStr)
						or die "Couldn't prepare: " . $dbh->errstr . "\n";

	# Execute the query
	$getFldH->execute
			or die "Couldn't execute: " . $getFldH->errstr;
	
	# Fetch each row and put it in an array
	while ($name = $getFldH->fetchrow) {
		push (@fldNames, $name);
	}

	# Close the handle
	$getFldH->finish;

	# Return the array, every element is field name 
	return @fldNames;
}

# Insert a record in the TEMPLATEASSOCIATION table
sub dbInsertTemplateAssoc {
my ($dbh, $siteName, $templateName, $siteFldIdMatchRef) = @_;

my @siteFldIdMatch = @$siteFldIdMatchRef;
my $siteId;
my $templateId;
my @templateFldIds;
my $templateFldId;
my $sqlStr;
my $i;
my $insH;

	# Get the SITEID
	$siteId = &dbGetSiteId($dbh, $siteName);
		
	# Get the TEMPLATEID
	$templateId = &dbGetTemplateId($dbh, $templateName);

	# Get the field ids for this Template
	@templateFldIds = &dbGetTemplateFldIds($dbh, $templateName);

	# Insert field values into the TEMPLATEASSOCIATION table 
	$i = 0;
	foreach $templateFldId (@templateFldIds) 
	{
	
		if (length $siteFldIdMatch[$i]) 
		{
		
			# Prepare the query
					$sqlStr="insert TEMPLATEASSOCIATION (SITEID, TEMPLATEID, \n"; 
			$sqlStr=$sqlStr."FLDID, TEMPLATEFLDID) \n values (";
			$sqlStr=$sqlStr."$siteId, $templateId, ";
			$sqlStr=$sqlStr.$siteFldIdMatch[$i].", $templateFldId)\n";

			print "\n";
			print $sqlStr;

			$insH = $dbh->prepare($sqlStr)
									or die "Couldn't prepare: " . $dbh->errstr . "\n";

			# Execute the query
			$insH->execute
					or die "Couldn't execute: " . $insH->errstr;

			# Close the handle
				$insH->finish;

			# Increment the counter
			$i++;

		}

	} # for
}

# Insert a record 
sub dbInsertFldValues {
my ($dbh, $siteName, $fldIdsRef, $fldListIdRef, $fldDepthsRef, $fldTagSeqRef, $fanoutRef, $treeLevelRef, $fldRelPosRef, $recBdry_fldidRef,
      $listSubRecRelPosRef, $listSubRecBdryFldIdRef, $fldKeywordsRef, $fldOmitwordsRef, $fldValuesRef,
      $fldBeginsWithRef, $fldEndsWithRef, $fldPreceededByRef, $fldFollowedByRef) = @_;

my @fldIds = @$fldIdsRef;
my @fldListId = @$fldListIdRef;
my @fldDepths = @$fldDepthsRef;
my @fldTagSeq = @$fldTagSeqRef;
my @fanout = @$fanoutRef;
my @treeLevel = @$treeLevelRef;
my @fldRelPos = @$fldRelPosRef;
my @recBdry_fldid = @$recBdry_fldidRef;
my @listSubRecRelPos = @$listSubRecRelPosRef;
my @listSubRecBdryFldId = @$listSubRecBdryFldIdRef;
my @fldKeywords = @$fldKeywordsRef;
my @fldOmitwords = @$fldOmitwordsRef;
my @fldValues = @$fldValuesRef;
my @fldBeginsWith = @$fldBeginsWithRef;
my @fldEndsWith =  @$fldEndsWithRef; 
my @fldPreceededBy =  @$fldPreceededByRef;
my @fldFollowedBy =  @$fldFollowedByRef;
my $siteId;
my $totFlds;
my $sqlStr;
my $maxRecNbr;
my $newRecNbr;
my $i;
my $insH;
my $j = -1;
my $increment = 0;

	# Get the SITEID
	$siteId = &dbGetSiteId($dbh, $siteName);
		
	# Get the max record number for this site
	$maxRecNbr = &dbGetMaxRecNbr($dbh, $siteName);

	# Calculate the record number of the new record
	$newRecNbr = $maxRecNbr+1;

	# Get the total number of fields
	$totFlds = $#fldIds;
	print "\n";
	print "Total Fields=" .  ($totFlds+1) . "\n";

	# Insert field values into the SAMPLEVALUES table 
	for $i (0 .. $#fldIds) 
	{
		# Don't insert fields which have no values	
		if (length $fldValues[$i] != 0)
		{

			# Prepare the query
			$sqlStr = "insert SAMPLEVALUES (SITEID, RECNBR, FLDID, LISTID, DEPTH, TAGSEQ, FANOUT, LEVEL, \n";
			$sqlStr = $sqlStr."RELPOS, RECBDRYFLDID, LISTSUBRECBDRYFLDID, LISTSUBRECRELPOS, KEYWORDS, OMITWORDS,\n";
			$sqlStr = $sqlStr."VALUE, BEGINSWITH, ENDSWITH, PRECEEDEDBY, FOLLOWEDBY) \n values (";
			$sqlStr = $sqlStr."$siteId, $newRecNbr, ".$fldIds[$i].", ";
			$sqlStr = $sqlStr.$fldListId[$i].",".$fldDepths[$i].", '".$fldTagSeq[$i]."', ". $fanout[$i]. ",". $treeLevel[$i]. ",";
			$sqlStr = $sqlStr.$fldRelPos[$i].", ".$recBdry_fldid[$i].", ".$listSubRecBdryFldId[$i].", ".$listSubRecRelPos[$i].",\"".$fldKeywords[$i]."\", \"";
			$sqlStr = $sqlStr.$fldOmitwords[$i]."\", \"". $fldValues[$i]."\", \"";
			$sqlStr = $sqlStr.$fldBeginsWith[$i]."\", \"". $fldEndsWith[$i]."\", \"". $fldPreceededBy[$i]."\", \"". $fldFollowedBy[$i]."\")\n";

			print "\n";
			print $sqlStr;

			$insH = $dbh->prepare($sqlStr)
								or die "Couldn't prepare: " . $dbh->errstr . "\n";

			# Execute the query
			$insH->execute
					or die "Couldn't execute: " . $insH->errstr;

			# Close the handle
			$insH->finish;
		}

	} # for
}

# Insert an extracted record 
sub dbInsertExtractedRecord {
my ($dbh, $siteName, $extractedRecsFldIdsRef, $extractedRecsListIdsRef, $extractedRecsParentIdsRef, $extractedRecsValuesRef) = @_;

my @extractedRecsFldIds = @$extractedRecsFldIdsRef;
my @extractedRecsValues = @$extractedRecsValuesRef;
my @extractedRecsListIds = @$extractedRecsListIdsRef;
my @extractedRecsParentIds = @$extractedRecsParentIdsRef;
my $sqlStr;
my $selH;
my $insH;
my $siteId;
my $templateId;
my @siteFldIds;
my $siteFldId;
my $fldId;
my $recNbr;
my $value;
my $listId;
my $i;
my $parentId;

	# Get the SITEID 
	$siteId = &dbGetSiteId($dbh, $siteName);

	# Obtain the max record number for this site 

	# Prepare the query
	$sqlStr = "select max(RECNBR) from EXTRACTEDRECS where \n";
	$sqlStr = $sqlStr."SITEID = $siteId\n";

	print "\n";
	print $sqlStr;

	$selH = $dbh->prepare($sqlStr)
			or die "Couldn't prepare: " . $dbh->errstr . "\n";

	# Execute the query
	$selH->execute
			or die "Couldn't execute: " . $selH->errstr;

	# Fetch the value
	$recNbr = $selH->fetchrow;

	# New record number 
	$recNbr++;

	# Close the handle
	$selH->finish;

	# Insert the values in the EXTRACTEDRECS table

        $i = 0;
	foreach $fldId (@extractedRecsFldIds) 
	{

		# Obtain the values to be inserted
		$listId = $extractedRecsListIds[$i];
		$parentId = $extractedRecsParentIds[$i];
		$value = $extractedRecsValues[$i];
		$i++;

		# Insert record in EXTRACTEDRECS table 

		# Prepare the query
		$sqlStr = "insert EXTRACTEDRECS (RECNBR, SITEID, FLDID, LISTID, PARENTID, VALUE) values \n";
		$sqlStr = $sqlStr."($recNbr, $siteId, $fldId, $listId, $parentId, \"$value\")\n";

		print "\n";
		print $sqlStr;

		$insH = $dbh->prepare($sqlStr) or die "Couldn't prepare: " . $dbh->errstr . "\n";

		# Execute the query
		$insH->execute	or die "Couldn't execute: " . $insH->errstr;

		# Close the handle
		$insH->finish;
	}
}

# Update a record 
sub dbUpdateFldValues1 {
my ($dbh, $siteName, $fldFldIdRef, $fldListIdRef, $fldKeywordsRef, $fldOmitwordsRef, $fldBeginsWithRef, $fldEndsWithRef, $fldPreceededByRef, $fldFollowedByRef) = @_;

my @fldIds = @$fldFldIdRef;
my @fldListId = @$fldListIdRef;
my @fldKeywords = @$fldKeywordsRef;
my @fldOmitwords = @$fldOmitwordsRef;
my @fldBeginsWith = @$fldBeginsWithRef;
my @fldEndsWith = @$fldEndsWithRef;
my @fldPreceededBy = @$fldPreceededByRef;
my @fldFollowedBy = @$fldFollowedByRef;
my $siteId;
my $totFlds;
my $sqlStr;
my $i;
my $updH;

	# Get the SITEID
	$siteId = &dbGetSiteId($dbh, $siteName);
		
	# Get the total number of fields
	$totFlds = $#fldIds;
	print "\n";
	print "Total Fields=" .  ($totFlds+1) . "\n";

	# Update field values into the FINALVALUES table 
	for $i (0 .. $totFlds) 
	{
	
		# Prepare the query
	        $sqlStr="update FINALVALUES \n";
		$sqlStr=$sqlStr."set KEYWORDS='".$fldKeywords[$i]."',\n";
		$sqlStr=$sqlStr."OMITWORDS='".$fldOmitwords[$i]."',\n";
		$sqlStr=$sqlStr."BEGINSWITH='".$fldBeginsWith[$i]."',\n";
		$sqlStr=$sqlStr."ENDSWITH='".$fldEndsWith[$i]."',\n";
		$sqlStr=$sqlStr."PRECEEDEDBY='".$fldPreceededBy[$i]."',\n";
		$sqlStr=$sqlStr."FOLLOWEDBY='".$fldFollowedBy[$i]."'\n";
		$sqlStr=$sqlStr."where SITEID=$siteId and FLDID=".$fldIds[$i]." and LISTID=". $fldListId[$i]."\n";

		print "\n";
		print $sqlStr;

		$updH = $dbh->prepare($sqlStr)
							or die "Couldn't prepare: " . $dbh->errstr . "\n";

		# Execute the query
		$updH->execute
				or die "Couldn't execute: " . $updH->errstr;

		# Close the handle
		$updH->finish;

	} # for
}

# Update a record 
sub dbUpdateFldValues2 {
my ($dbh, $siteName, $fldFldIdRef, $fldListIdRef, $fldRelPosRef, $fldRelPosAdjRef, $fldFanoutRef, $fldFanoutAdjRef, $fldLevelRef, $fldListSubRecRelPosRef, $fldListSubRecRelPosAdjRef) = @_;

my @fldIds = @$fldFldIdRef;
my @fldListId = @$fldListIdRef;
my @fldRelPos = @$fldRelPosRef;
my @fldRelPosAdj = @$fldRelPosAdjRef;
my @fldFanout = @$fldFanoutRef;
my @fldFanoutAdj = @$fldFanoutAdjRef;
my @fldLevel = @$fldLevelRef;
my @fldListSubRecRelPos = @$fldListSubRecRelPosRef;
my @fldListSubRecRelPosAdj = @$fldListSubRecRelPosAdjRef;
my $siteId;
my $totFlds;
my $sqlStr;
my $i;
my $updH;

	# Get the SITEID
	$siteId = &dbGetSiteId($dbh, $siteName);
		
	# Get the total number of fields
	$totFlds = $#fldIds;
	print "\n";
	print "Total Fields=" .  ($totFlds+1) . "\n";

	# Update field values into the FINALVALUES table 
	for $i (0 .. $totFlds) 
	{
	
		# Prepare the query
	        $sqlStr="update FINALVALUES \n";
		$sqlStr=$sqlStr."set RELPOS=".$fldRelPos[$i].",\n";
		$sqlStr=$sqlStr."RELPOSADJ=".$fldRelPosAdj[$i].",\n";
		$sqlStr=$sqlStr."FANOUT=".$fldFanout[$i].",\n";
		$sqlStr=$sqlStr."FANOUTADJ=".$fldFanoutAdj[$i].",\n";
		$sqlStr=$sqlStr."LEVEL='".$fldLevel[$i]."',\n";
		$sqlStr=$sqlStr."LISTSUBRECRELPOS=".$fldListSubRecRelPos[$i].",\n";
		$sqlStr=$sqlStr."LISTSUBRECRELPOSADJ=".$fldListSubRecRelPosAdj[$i]."\n";
		$sqlStr=$sqlStr."where SITEID=$siteId and FLDID=".$fldIds[$i]." and LISTID=". $fldListId[$i]."\n";

		print "\n";
		print $sqlStr;

		$updH = $dbh->prepare($sqlStr)
							or die "Couldn't prepare: " . $dbh->errstr . "\n";

		# Execute the query
		$updH->execute
				or die "Couldn't execute: " . $updH->errstr;

		# Close the handle
		$updH->finish;

	} # for
}

# Re-Calculate the value for each field
sub dbDeriveParams {

my ($dbh, $siteName) = @_;
my $siteId;
my @fldIds;
my $sqlStr;
my $totFlds;
my $selH;
my $row;
my $i;
my @listId;
my @depth;
my @tagSeq;
my @relPos;
my @fanout;
my @treeLevel;
my @recBdry_fldid;
my @listSubRecBdryFldId;
my @listSubRecRelPos;
my @keywords;
my @omitwords;
my @beginsWith;
my @endsWith;
my @preceededBy;
my @followedBy;
my @value;
my $freq;
my $depth;
my $depthMax;
my $tagSeq;
my $first;
my $relPos;
my $fanout;
my $treeLevel;
my $relPosMax;
my $listSubRecRelPos;
my $listSubRecRelPosMax;
my $listSubRecRelPosAdj;
my $keywords;
my $omitwords;
my $beginsWith;
my $endsWith;
my $preceededBy;
my $followedBy;
my $minLen;
my $maxLen;
my $depthAdj;
my $relPosAdj;
my $fanoutAdj = 0;
my $treeLevelAdj = 0;
my $minLenAdj;
my $delH;
my $insH;
my %depthTagSeq;
my %levelFanout;
my @depthTagPairs;
my $valLen;
my @listId_1;
my @depth_1;
my @tagSeq_1;
my @relPos_1;
my @fanout_1;
my @treeLevel_1;
my @recBdry_fldid_1;
my @listSubRecRelPos_1;
my @listSubRecBdryFldId_1;
my @keywords_1;
my @omitwords_1;
my @beginsWith_1;
my @endsWith_1;
my @preceededBy_1;
my @followedBy_1;
my @value_1;
my @listId_O;
my @depth_O;
my @tagSeq_O;
my @relPos_O;
my @fanout_O;
my @treeLevel_O;
my @recBdry_fldid_O;
my @listSubRecRelPos_O;
my @listSubRecBdryFldId_O;
my @keywords_O;
my @omitwords_O;
my @beginsWith_O;
my @endsWith_O;
my @preceededBy_O;
my @followedBy_O;
my @value_O;
my $j;
my $m;
my $t;
my $l;
my $num_recBdryFldId;
my $recBdryIndex;
my $listBdryIndex;
my $loop;
my $case;
my $HIGHVAL = 9999999;
my $TINYINT_HIGHVAL = 255;
		

	undef %depthTagSeq;
	undef %levelFanout;
	undef @listId;
	undef @depth;
	undef @tagSeq;
	undef @relPos;
	undef @fanout;
	undef @treeLevel;
	undef @recBdry_fldid;
	undef @keywords;
	undef @omitwords;
	undef @beginsWith;
	undef @endsWith;
	undef @preceededBy;
	undef @followedBy;
	undef @value;
	
	# Get the SITEID
	$siteId = &dbGetSiteId($dbh, $siteName);

	# Get all the field ids for this site
	@fldIds = &dbGetFldIdsWithValues($dbh, $siteName);

	# Get the total number of fields
	$totFlds = $#fldIds;
	print "\n";
	print "Total Fields=" .  ($totFlds+1) . "\n";
	
	# Get all the list ids for this site
	#@listId = &dbGetListIds($dbh, $siteName);
	
	
	# For each field calculate the various parameters 
	# and insert the calculated values in FINALVALUES
	for $i (0 .. $totFlds) 
	{
		
		# Create the sql string 
		$sqlStr ="select LISTID, DEPTH, TAGSEQ, RELPOS, FANOUT, LEVEL, RECBDRYFLDID, LISTSUBRECBDRYFLDID,";
		$sqlStr = $sqlStr. "LISTSUBRECRELPOS, KEYWORDS, OMITWORDS, VALUE, BEGINSWITH, ENDSWITH, PRECEEDEDBY, FOLLOWEDBY ";
		$sqlStr = $sqlStr."from SAMPLEVALUES where FLDID=".$fldIds[$i]." order by RECNBR, LISTID\n";

		print "\n";
		print $sqlStr;

		# Prepare the query
		$selH = $dbh->prepare($sqlStr)
							or die "Couldn't prepare: " . $dbh->errstr . "\n";

		# Execute the query
		$selH->execute
				or die "Couldn't execute: " . $selH->errstr;
		
		# Fetch each row and put values in respective array
		while ($row = $selH->fetchrow_hashref) 
		{
			push (@listId, $row->{'LISTID'});
			push (@depth, $row->{'DEPTH'});
			push (@tagSeq, $row->{'TAGSEQ'});
			push (@relPos, $row->{'RELPOS'});
			push (@fanout, $row->{'FANOUT'});
			push (@treeLevel, $row->{'LEVEL'});
			push (@recBdry_fldid, $row->{'RECBDRYFLDID'});
			push (@listSubRecBdryFldId, $row->{'LISTSUBRECBDRYFLDID'});
			push (@listSubRecRelPos, $row->{'LISTSUBRECRELPOS'});
			push (@keywords, $row->{'KEYWORDS'});
			push (@omitwords, $row->{'OMITWORDS'});
			push (@beginsWith, $row->{'BEGINSWITH'});
			push (@endsWith, $row->{'ENDSWITH'});
			push (@preceededBy, $row->{'PRECEEDEDBY'});
			push (@followedBy, $row->{'FOLLOWEDBY'});
			push (@value, $row->{'VALUE'});
		}

		# Close the handle
		$selH->finish;
		
		#Seperate values corresponding to ListId == 1 and values corresponding to ListId > 1
		#Perform the claulations separately for both sets and
		#store both in FINALVALUES table
		
		if ( ($#value + 1) > 0 )
		{
		for $j (0..$#listId)
		{
			if( $listId[$j] == 1 )
			{
				push ( @listId_1, $listId[$j] );
				push ( @depth_1, $depth[$j] );
				push ( @tagSeq_1, $tagSeq[$j] );
				push ( @relPos_1, $relPos[$j] );
				push (@fanout_1, $fanout[$j] );
				push (@treeLevel_1, $treeLevel[$j]);
				push ( @recBdry_fldid_1, $recBdry_fldid[$j] );
				push ( @listSubRecRelPos_1, $listSubRecRelPos[$j] );
				push ( @listSubRecBdryFldId_1, $listSubRecBdryFldId[$j] );
				push ( @keywords_1, $keywords[$j] );
				push ( @omitwords_1, $omitwords[$j] );
				push ( @beginsWith_1, $beginsWith[$j] );
				push ( @endsWith_1, $endsWith[$j] );
				push ( @preceededBy_1, $preceededBy[$j] );
				push ( @followedBy_1, $followedBy[$j] );
				push ( @value_1, $value[$j] );
			}
			if( $listId[$j] > 1 )
			{
				push ( @listId_O, $listId[$j] );
				push ( @depth_O, $depth[$j] );
				push ( @tagSeq_O, $tagSeq[$j] );
				push ( @relPos_O, $relPos[$j] );
				push ( @fanout_O, $fanout[$j] );
				push ( @treeLevel_O, $treeLevel[$j]);
				push ( @recBdry_fldid_O, $recBdry_fldid[$j] );
				push ( @listSubRecRelPos_O, $listSubRecRelPos[$j] );
				push ( @listSubRecBdryFldId_O, $listSubRecBdryFldId[$j] );
				push ( @keywords_O, $keywords[$j] );
				push ( @omitwords_O, $omitwords[$j] );
				push ( @beginsWith_O, $beginsWith[$j] );
				push ( @endsWith_O, $endsWith[$j] );
				push ( @preceededBy_O, $preceededBy[$j] );
				push ( @followedBy_O, $followedBy[$j] );
				push ( @value_O, $value[$j] );
			}
		}
			
			
		#Do the various calculations now
				
		if( ($#listId_1 + 1) > 0 )
		{
			$loop = 2;
			$case = 1;
		}
		else
		{
			$loop = 1;
			$case = 0;
		}
		
		for $m(1..$loop)
		{
			if( $case == 1 )
			{
				undef @listId;
				undef @depth;
				undef @tagSeq;
				undef @relPos;
				undef @fanout;
				undef @treeLevel;
				undef @recBdry_fldid;
				undef @listSubRecRelPos;
				undef @listSubRecBdryFldId;
				undef @keywords;
				undef @omitwords;
				undef @beginsWith;
				undef @endsWith;
				undef @preceededBy;
				undef @followedBy;
				undef @value;
				
				if( $m == 1 )
				{
					push @listId , @listId_1;
					push @depth , @depth_1;
					push @tagSeq , @tagSeq_1;
				    	push @relPos , @relPos_1;
				    	push @fanout, @fanout_1;
				    	push @treeLevel, @treeLevel_1;
					push @recBdry_fldid , @recBdry_fldid_1;
					push @listSubRecRelPos , @listSubRecRelPos_1;
					push @listSubRecBdryFldId , @listSubRecBdryFldId_1;
					push @keywords , @keywords_1;
					push @omitwords , @omitwords_1;
					push @beginsWith , @beginsWith_1;
					push @endsWith , @endsWith_1;
					push @preceededBy , @preceededBy_1;
					push @followedBy , @followedBy_1;
 					push @value , @value_1;
				}
				if( $m == 2 )
				{
					push @listId , @listId_O;
					push @depth , @depth_O;
					push @tagSeq , @tagSeq_O;
					push @relPos , @relPos_O;
					push @fanout, @fanout_O;
				    	push @treeLevel, @treeLevel_O;
					push @recBdry_fldid , @recBdry_fldid_O;
					push @listSubRecRelPos , @listSubRecRelPos_O;
					push @listSubRecBdryFldId , @listSubRecBdryFldId_O;
					push @keywords , @keywords_O;
					push @omitwords , @omitwords_O;
					push @beginsWith , @beginsWith_O;
					push @endsWith , @endsWith_O;
					push @preceededBy , @preceededBy_O;
					push @followedBy , @followedBy_O;
					push @value , @value_O;
				}
		
			}
		
		if ( ($#value + 1) > 0 )
		{
		
			#Creating depthTagSeq pairs -hashes of hashes
			 my $j = 0;
			 my $hashkey;
			 foreach (@depth)
			 {
			 	$hashkey = $_.$tagSeq[$j];
			 	$depthTagSeq{$hashkey}{$_} = $tagSeq[$j] if not exists $depthTagSeq{$hashkey};
			 	$j++;
			  }
				
			# Create the final depth and tag sequence values
			my $dt;
			my $d;
			$depth = "";
			$tagSeq = "";
			for $dt (sort {$a <=> $b} keys %depthTagSeq)
			{
				for $d (keys %{ $depthTagSeq{ $dt } } )
				{
					$depth=$depth . $d . ";";
					$tagSeq=$tagSeq . $depthTagSeq{$dt}{$d} . ":";
				}
			}
				
				
			#Creating levelFanout pairs -hashes of hashes
			$j = 0;
		 	$hashkey = " ";
		 	foreach (@treeLevel)
		 	{
				$hashkey = $_.$fanout[$j];
				$levelFanout{$hashkey}{$_} = $fanout[$j] if not exists $levelFanout{$hashkey};
				$j++;
		 	 }
		  
			# Create the final level and fanout values
		   	my $dt;
		   	$treeLevel = "";
		   	$fanout = "";
			for $dt (sort {$a <=> $b} keys %levelFanout)
			{
				for $d (keys %{ $levelFanout{ $dt } } )
				{
					$treeLevel = $treeLevel . $d . ";";
					$fanout = $fanout . $levelFanout{$dt}{$d} . ":";
				}
			}
		
			#get the adjustment values
			($relPos, $relPosAdj) = &dbGetValueAdj(\@relPos);
			($listSubRecRelPos, $listSubRecRelPosAdj) = &dbGetValueAdj(\@listSubRecRelPos);
		
			undef $fanout;
			($fanout, $fanoutAdj) = &dbGetValueAdj(\@fanout);
			
		
			# if a boundary field id is 0, get its index in the array of boundary fields
			$t = 0;
			$num_recBdryFldId = $#recBdry_fldid;
			for $t (0..$num_recBdryFldId )
			{
				$recBdryIndex = $t;
				if( $recBdry_fldid[$t] != 0 )
				{	
					last;
				}
					
			}
		
			$l = 0;
			$num_recBdryFldId = $#listSubRecBdryFldId;
			for $l (0..$num_recBdryFldId )
			{
				$listBdryIndex = $l;
				if( $listSubRecBdryFldId[$l] != 0 )
				{
					last;
				}
			}

			# combine values into a single value separated by ';'
			$keywords = "";
			$keywords = &combineValues(\@keywords);
			$omitwords = "";
			$omitwords = &combineValues(\@omitwords);
			$beginsWith = "";
			$beginsWith = &combineValues(\@beginsWith);
			$endsWith = "";
			$endsWith = &combineValues(\@endsWith);
			$preceededBy = "";
			$preceededBy = &combineValues(\@preceededBy);
			$followedBy = "";
			$followedBy = &combineValues(\@followedBy);
		
		
		
			# Get the min and max length of the values
			$minLen=1000;
			$maxLen=0;
			foreach (@value)
			{
				$valLen=length $_;
				if ($minLen > $valLen) 
				{
					$minLen=$valLen;
				}

				if ($maxLen < $valLen)
				{
					$maxLen=$valLen;
				}
			}

			$minLenAdj = $maxLen - $minLen;

		# End of calculations

		# Delete the existing entry in FINALVALUES table
		# Create the sql string 
		$sqlStr = "delete from FINALVALUES where SITEID=$siteId and FLDID=".$fldIds[$i]."\n";
		$sqlStr = $sqlStr. " and LISTID=".$listId[0]."\n";

		print "\n";
		print $sqlStr;

		# Prepare the query
		$delH = $dbh->prepare($sqlStr)
							or die "Couldn't prepare: " . $dbh->errstr . "\n";

		# Execute the query
		$delH->execute
				or die "Couldn't execute: " . $insH->errstr;

		# Close the handle
		$delH->finish;

		# Insert the values in the FINALVALUES table
		# Create the sql string 
		$sqlStr = "insert FINALVALUES (SITEID, FLDID, LISTID, DEPTH, TAGSEQ, RELPOS, FANOUT, LEVEL, RECBDRYFLDID,\n";
		$sqlStr = $sqlStr."LISTSUBRECBDRYFLDID, LISTSUBRECRELPOS,\n";
		$sqlStr = $sqlStr."MINLEN, KEYWORDS, OMITWORDS, RELPOSADJ, LISTSUBRECRELPOSADJ, FANOUTADJ, LEVELADJ, MINLENADJ, \n";
		$sqlStr = $sqlStr."BEGINSWITH, ENDSWITH, PRECEEDEDBY, FOLLOWEDBY) \n";
		$sqlStr = $sqlStr."values($siteId, ".$fldIds[$i]."," .$listId[0].", '$depth', '$tagSeq', $relPos, '$fanout', '$treeLevel', ".$recBdry_fldid[$recBdryIndex].", ";
		$sqlStr = $sqlStr. $listSubRecBdryFldId[$listBdryIndex].", ".$listSubRecRelPos.",";
		$sqlStr = $sqlStr."$minLen, '$keywords', '$omitwords', $relPosAdj,  $listSubRecRelPosAdj, $fanoutAdj, $treeLevelAdj, $minLenAdj, ";
		$sqlStr = $sqlStr." '$beginsWith','$endsWith', '$preceededBy','$followedBy')\n";

		print "\n";
		print $sqlStr;

		# Prepare the query
		$insH = $dbh->prepare($sqlStr)
							or die "Couldn't prepare: " . $dbh->errstr . "\n";

		# Execute the query
		$insH->execute
				or die "Couldn't execute: " . $insH->errstr;

		# Close the handle
		$insH->finish;

		# Undefine all the arrays to be used for the next field
		undef %depthTagSeq;
		undef %levelFanout;
		undef @listId;
		undef @depth;
		undef @tagSeq;
		undef @relPos;
		undef @fanout;
		undef @treeLevel;
		undef @recBdry_fldid;
		undef @keywords;
		undef @omitwords;
		undef @beginsWith;
		undef @endsWith;
		undef @preceededBy;
		undef @followedBy;
		undef @value;
		}#if ( ($#value + 1) > 0 )
	}#end for $m
	
		undef @listId_1;
		undef @depth_1;
		undef @tagSeq_1;
		undef @relPos_1;
		undef @fanout_1;
		undef @treeLevel_1;
		undef @recBdry_fldid_1;
		undef @listSubRecRelPos_1;
		undef @listSubRecBdryFldId_1;
		undef @keywords_1;
		undef @omitwords_1;
		undef @beginsWith_1;
		undef @endsWith_1;
		undef @preceededBy_1;
		undef @followedBy_1;
	 	undef @value_1;
		undef @listId_O;
		undef @depth_O;
		undef @tagSeq_O;
		undef @relPos_O;
		undef @fanout_O;
		undef @treeLevel_O;
		undef @recBdry_fldid_O;
		undef @listSubRecRelPos_O;
		undef @listSubRecBdryFldId_O;
		undef @keywords_O;
		undef @omitwords_O;
		undef @beginsWith_O;
		undef @endsWith_O;
		undef @preceededBy_O;
		undef @followedBy_O;
	 	undef @value_O;
	 	undef @listSubRecBdryFldId;
		undef @listSubRecRelPos;
	}#if ( ($#value + 1) > 0 )
    }#end for $i
}#end sub dbDeriveParams

#subRoutine to combine values into a single value separated by ';'
sub combineValues {
my ($valuesRef) = @_;
my @values = @$valuesRef;
my $value;

	foreach (@values)
	{
		if (length $_ > 0) 
		{
			$value = $value.$_.";";
		}
	}
		
	return $value;
}#end subCombineValues


#get the adjustment value
sub dbGetValueAdj
{
  my ($valuesRef) = @_;
  my @values = @$valuesRef;
  my $first;
  my $valueMin;
  my $valueMax;
  my $valueAdj;
  my $HIGHVAL = 9999999;
  my $TINYINT_HIGHVAL = 255;
  
  
		$first = 1;
		$valueMin = 0;
		$valueMax = 0;
		foreach (@values)
		{
			next if ( ($_ == $HIGHVAL) || ($_ == $TINYINT_HIGHVAL) );
			# If first value then assign that as relPos
			if ($first == 1)
			{
				$valueMin = $_;
				$valueMax = $_;
				$first = 0;
			}
			else 
			{
				if ($valueMin > $_)
				{
					$valueMin = $_;
				} 

				if ($valueMax < $_)
				{
					$valueMax = $_;
				}
			}
		}
		
		$valueAdj = $valueMax - $valueMin;
		
    return ($valueMin, $valueAdj);		
}#end sub dbGetValueAdj



# Get the field definition
sub dbGetFldDef {
my ($dbh, $siteName, $fldId) = @_;
my $getDefsH;
my $siteId;
my $query;
my $output;

	# Get the SITEID assigned to this site from the site table
	$siteId = &dbGetSiteId($dbh, $siteName);

	# Prepare the query
	$query = "select SF.FLDID, FLDNAME, FLDTYPE, SF.LEVELID, DEPTH, TAGSEQ, RELPOS, RECBDRYFLDID, \n";
	$query = $query ."MINLEN, KEYWORDS, OMITWORDS, RELPOSADJ, MINLENADJ, LISTID, \n";
	$query = $query ."LISTSUBRECBDRYFLDID, LISTSUBRECRELPOS, LISTSUBRECRELPOSADJ,\n";
	$query = $query ."FANOUT, LEVEL, FANOUTADJ, BEGINSWITH, ENDSWITH, PRECEEDEDBY, FOLLOWEDBY\n";
	$query = $query ."from SITEFIELDS SF, FINALVALUES FV \n";
	$query = $query ."where SF.SITEID = FV.SITEID \n";
	$query = $query ."and  SF.FLDID = FV.FLDID \n";
	$query = $query ."and  SF.SITEID = $siteId \n";
	$query = $query ."and  SF.FLDID = $fldId\n";

	print "\n";
	print "$query\n";

	$getDefsH = $dbh->prepare($query)
						or die "Couldn't prepare: " . $dbh->errstr . "\n";

	# Execute the query
	$getDefsH->execute
			or die "Couldn't execute: " . $getDefsH->errstr;

	# Fetch all rows
	$output = $getDefsH->fetchall_arrayref
	                  or die "$getDefsH->errstr\n";

	# Close the handle
	$getDefsH->finish;

	# Return the ouput
	return $output;
}

# Subroutine to get the list of sub-records boundary field for a given field
sub dbGetListSubRecBdryFldIds {
my ($dbh, $siteName) = @_;
my $siteId;
my $sqlStr;
my $selH;
my $allrows;
	  
	# get siteId
	$siteId = &dbGetSiteId($dbh, $siteName);
	  
	# Make the sql string 
	$sqlStr = "select distinct FLDID, LISTSUBRECBDRYFLDID from FINALVALUES \n";
	$sqlStr = $sqlStr." where SITEID = $siteId and LISTSUBRECBDRYFLDID != 0 \n";
	$sqlStr = $sqlStr." and FLDID != LISTSUBRECBDRYFLDID \n ";

	print "\n";
	print ("\n$sqlStr");

	# Prepare the query
	$selH = $dbh->prepare($sqlStr)
		       or die "Couldn't prepare: " . $dbh->errstr . "\n";

	# Execute the query
	$selH->execute
			or die "Couldn't execute: " . $selH->errstr;

	# Fetch all rows as a reference to an array of arrays of references to each row
	$allrows = $selH->fetchall_arrayref
		  or die "$selH->errstr\n";


	# Close the handle
	$selH->finish;

	# Return the array
    return  $allrows; 
}

#subRoutine to return levelIds of all flds in the array argument
sub dbGetLevelIds{
      my ($dbh, $siteName, $fldids) = @_;
          my @fldIds = @$fldids;
	  my $siteId;
	  my $sqlStr;
	  my $selH;
	  my $levelId;
	  my @values;
	  my $i;
	  my $row;
	  my @fldId;
	  my @levelIds;
	  my %fldIdHash;
	  
	  # get siteId
	  $siteId = &dbGetSiteId($dbh, $siteName);
	  
	 
	  # Make the sql string 
	  foreach $i (@fldIds)
	  {
	  	if ( defined $i )
	  	{
			my @values;
			$sqlStr = "select s.FLDID, LEVELID, RECBDRYFLDID from SITEFIELDS s, FINALVALUES f \n";
			$sqlStr = $sqlStr." where s.SITEID = $siteId \n";
			$sqlStr = $sqlStr." and s.SITEID = f.SITEID \n ";
			$sqlStr = $sqlStr." and s.FLDID = $i \n ";
			$sqlStr = $sqlStr." and s.FLDID = f.FLDID \n ";

			print "\n";
			print $sqlStr;

			# Prepare the query
			$selH = $dbh->prepare($sqlStr)
							or die "Couldn't prepare: " . $dbh->errstr . "\n";

			# Execute the query
			$selH->execute
					or die "Couldn't execute: " . $selH->errstr;


			$row = $selH->fetchrow_hashref;
			push (@values, $row->{'LEVELID'}, $row->{'RECBDRYFLDID'});
			$fldIdHash{$row->{'FLDID'}} = \@values;



			#push (@levelIds, $row->{'LEVELID'});


			# Close the handle
			$selH->finish;
		}#end if
	}#end foreach
		
	# Return the hash
	return \%fldIdHash; 
	   	
}

1;
