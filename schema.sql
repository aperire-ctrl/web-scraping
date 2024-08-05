create table SITES (
	SITEID smallint unsigned auto_increment primary key,
	SITENAME varchar(30) not null,
	key (SITENAME),
	unique index sites_01 (SITENAME)
);

create table SITEFIELDS (
	SITEID smallint unsigned not null references SITES(SITEID), 
	LEVELID smallint unsigned not null,
	PARENTID int unsigned not null,
	FLDID int unsigned auto_increment primary key, 
	FLDSEQ varchar(10) not null,
	FLDNAME varchar(30) not null,
	FLDTYPE char(1) not null default 'B',
	MANDATORY_FLG char(1) not null default 'N',
	LIST_FLG char(1) not null default 'N',
	SUBRECORD_FLG char(1) not null default 'N',
	MANDATORY_FLG char(1) not null default 'N',
	unique index sitefields_01 (SITEID, FLDNAME),
	index sitefields_02 (FLDID, FLDNAME)
);


create table SAMPLEVALUES (
	SITEID smallint unsigned not null references SITES(SITEID), 
	RECNBR tinyint unsigned not null,
	FLDID tinyint unsigned not null references SITEFIELDS(FLDID),
	LISTID tinyint unsigned not null default 0,
	DEPTH tinyint unsigned not null,
	TAGSEQ varchar(255) not null,
	RELPOS int unsigned not null,
	RECBDRYFLDID int unsigned not null,
	LISTSUBRECBDRYFLDID int unsigned not null default 0,
	LISTSUBRECRELPOS int unsigned not null,
	KEYWORDS varchar(255), 
	OMITWORDS varchar(255),
	FANOUT int unsigned not null,
	LEVEL int unsigned not null, 
	VALUE varchar(255) not null,
	BEGINSWITH varchar(255),
	ENDSWITH varchar(255),
	PRECEEDEDBY varchar(255),
	FOLLOWEDBY varchar(255),
	primary key (SITEID, RECNBR, FLDID, LISTID),
	unique index samplevalues_01 (SITEID, RECNBR, FLDID, LISTID),
	index samplevalues_02 (SITEID, FLDID)
);

create table FINALVALUES (
	SITEID smallint unsigned not null references SITES(SITEID), 
	FLDID tinyint unsigned not null references SITEFIELDS(FLDID),
	LISTID tinyint unsigned not null,
	DEPTH varchar(255) not null,
	TAGSEQ varchar(255) not null,
	RELPOS int unsigned not null,
	RECBDRYFLDID int unsigned not null,
	LISTSUBRECBDRYFLDID int unsigned not null,
	LISTSUBRECRELPOS int unsigned not null,
	KEYWORDS varchar(255), 
	OMITWORDS varchar(255),
	FANOUT varchar(255) not null,
	LEVEL varchar(255) not null,
	BEGINSWITH varchar(255),
	ENDSWITH varchar(255),
	PRECEEDEDBY varchar(255),
	FOLLOWEDBY varchar(255),
	RELPOSADJ int unsigned not null default 0,
	FANOUTADJ int unsigned not null default 0,
	LEVELADJ int unsigned not null default 0,
	LISTSUBRECRELPOSADJ tinyint unsigned not null default 0,
	primary key (SITEID, FLDID, LISTID),
	unique index finalvalues_01 (SITEID, FLDID, LISTID)
);

create table TEMPLATES (
	TEMPLATEID smallint unsigned auto_increment primary key,
	TEMPLATENAME varchar(30) not null,
	key (TEMPLATENAME),
	unique index templates_01 (TEMPLATENAME)
);

create table TEMPLATEFIELDS (
	TEMPLATEID smallint unsigned not null references TEMPLATES(TEMPLATEID), 
	TEMPLATEFLDID tinyint unsigned auto_increment primary key, 
	TEMPLATEFLDNAME varchar(30) not null,
	unique index templatefields_01 (TEMPLATEID, TEMPLATEFLDNAME)
);

create table TEMPLATEASSOCIATION (
	SITEID smallint unsigned not null references SITES (SITEID), 
	TEMPLATEID smallint unsigned not null references TEMPLATES(TEMPLATEID), 
	FLDID smallint unsigned not null references SITEFIELDS (FLDID), 
	TEMPLATEFLDID smallint unsigned not null references TEMPLATEFIELDS(TEMPLATEFLDID), 
	unique index templateassociation_01 (FLDID, TEMPLATEFLDID),
	index templateassociation_02 (SITEID)
);

create table EXTRACTEDRECS (
	RECNBR int not null,
	SITEID smallint not null references SITES(SITEID),
	FLDID smallint unsigned not null references SITEFIELDS (FLDID), 
	VALUE varchar(255),
	LISTID tinyint unsigned not null references FINALVALUES (LISTID),
	unique index extractedrecs_01 (RECNBR, SITEID, FLDID, LISTID),
	index extractedrecs_02 (SITEID)
);
