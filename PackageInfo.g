#
# RepnDecomp: Decompose representations of finite groups into irreducibles
#
# This file contains package meta data. For additional information on
# the meaning and correct usage of these fields, please consult the
# manual of the "Example" package as well as the comments in its
# PackageInfo.g file.
#
SetPackageInfo( rec(

PackageName := "RepnDecomp",
Subtitle := "Decompose representations of finite groups into irreducibles",
Version := "0.1",
Date := "20/04/2019", # dd/mm/yyyy format

Persons := [
  rec(
    IsAuthor := true,
    IsMaintainer := true,
    FirstNames := "Kaashif",
    LastName := "Hymabaccus",
    WWWHome := "https://kaashif.co.uk",
    Email := "kaashif@kaashif.co.uk",
    Place := "Oxford",
    Institution := "University of Oxford",
  ),
  rec(
    IsAuthor := false,
    IsMaintainer := false,
    FirstNames := "Dmitrii",
    LastName := "Pasechnik",
    Place := "Oxford",
    Institution := "University of Oxford",
  ),
],

#SourceRepository := rec( Type := "TODO", URL := "URL" ),
#IssueTrackerURL := "TODO",
#SupportEmail := "TODO",

PackageWWWHome := "http://gitlab.com/kaashif/decomp/",

PackageInfoURL := Concatenation( ~.PackageWWWHome, "PackageInfo.g" ),
README_URL     := Concatenation( ~.PackageWWWHome, "README.md" ),
ArchiveURL     := Concatenation( ~.PackageWWWHome,
                                 "/", ~.PackageName, "-", ~.Version ),

ArchiveFormats := ".tar.gz",

##  Status information. Currently the following cases are recognized:
##    "accepted"      for successfully refereed packages
##    "submitted"     for packages submitted for the refereeing
##    "deposited"     for packages for which the GAP developers agreed
##                    to distribute them with the core GAP system
##    "dev"           for development versions of packages
##    "other"         for all other packages
##
Status := "dev",

AbstractHTML   :=  "",

PackageDoc := rec(
  BookName  := "RepnDecomp",
  ArchiveURLSubset := ["public"],
  HTMLStart := "public/chap0.html",
  PDFFile   := "public/manual.pdf",
  SixFile   := "public/manual.six",
  LongTitle := "Decompose representations of finite groups into irreducibles",
),

Dependencies := rec(
  GAP := ">= 4.10",
  NeededOtherPackages := [ [ "GAPDoc", ">= 1.6.1" ],
                           [ "GRAPE", ">= 4.8.1" ] ],
  SuggestedOtherPackages := [ ],
  ExternalConditions := [ ],
),

AvailabilityTest := function() return true; end,

TestFile := "tst/testall.g",

#Keywords := [ "TODO" ],

));
