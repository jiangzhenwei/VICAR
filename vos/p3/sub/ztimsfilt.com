$!****************************************************************************
$!
$! Build proc for MIPL module ztimsfilt
$! VPACK Version 1.5, Tuesday, March 30, 1993, 22:03:26
$!
$! Execute by entering:		$ @ztimsfilt
$!
$! The primary option controls how much is to be built.  It must be in
$! the first parameter.  Only the capitalized letters below are necessary.
$!
$! Primary options are:
$!   COMPile     Compile the program modules
$!   ALL         Build a private version, and unpack the PDF and DOC files.
$!   STD         Build a private version, and unpack the PDF file(s).
$!   SYStem      Build the system version with the CLEAN option, and
$!               unpack the PDF and DOC files.
$!   CLEAN       Clean (delete/purge) parts of the code, see secondary options
$!   UNPACK      All files are created.
$!   REPACK      Only the repack file is created.
$!   SOURCE      Only the source files are created.
$!   SORC        Only the source files are created.
$!               (This parameter is left in for backward compatibility).
$!   IMAKE       Only the IMAKE file (used with the VIMAKE program) is created.
$!
$!   The default is to use the STD parameter if none is provided.
$!
$!****************************************************************************
$!
$! The secondary options modify how the primary option is performed.
$! Note that secondary options apply to particular primary options,
$! listed below.  If more than one secondary is desired, separate them by
$! commas so the entire list is in a single parameter.
$!
$! Secondary options are:
$! COMPile,ALL:
$!   DEBug      Compile for debug               (/debug/noopt)
$!   PROfile    Compile for PCA                 (/debug)
$!   LISt       Generate a list file            (/list)
$!   LISTALL    Generate a full list            (/show=all)   (implies LIST)
$! CLEAN:
$!   OBJ        Delete object and list files, and purge executable (default)
$!   SRC        Delete source and make files
$!
$!****************************************************************************
$!
$ write sys$output "*** module ztimsfilt ***"
$!
$ Create_Source = ""
$ Create_Repack =""
$ Create_Imake = ""
$ Do_Make = ""
$!
$! Parse the primary option, which must be in p1.
$ primary = f$edit(p1,"UPCASE,TRIM")
$ if (primary.eqs."") then primary = " "
$ secondary = f$edit(p2,"UPCASE,TRIM")
$!
$ if primary .eqs. "UNPACK" then gosub Set_Unpack_Options
$ if (f$locate("COMP", primary) .eqs. 0) then gosub Set_Exe_Options
$ if (f$locate("ALL", primary) .eqs. 0) then gosub Set_All_Options
$ if (f$locate("STD", primary) .eqs. 0) then gosub Set_Default_Options
$ if (f$locate("SYS", primary) .eqs. 0) then gosub Set_Sys_Options
$ if primary .eqs. " " then gosub Set_Default_Options
$ if primary .eqs. "REPACK" then Create_Repack = "Y"
$ if primary .eqs. "SORC" .or. primary .eqs. "SOURCE" then Create_Source = "Y"
$ if primary .eqs. "IMAKE" then Create_Imake = "Y"
$ if (f$locate("CLEAN", primary) .eqs. 0) then Do_Make = "Y"
$!
$ if Create_Repack then gosub Repack_File
$ if Create_Source then gosub Source_File
$ if Create_Imake then gosub Imake_File
$ if Do_Make then gosub Run_Make_File
$ exit
$!
$ Set_Unpack_Options:
$   Create_Repack = "Y"
$   Create_Source = "Y"
$   Create_Imake = "Y"
$ Return
$!
$ Set_EXE_Options:
$   Create_Source = "Y"
$   Create_Imake = "Y"
$   Do_Make = "Y"
$ Return
$!
$ Set_Default_Options:
$   Create_Source = "Y"
$   Create_Imake = "Y"
$   Do_Make = "Y"
$ Return
$!
$ Set_All_Options:
$   Create_Source = "Y"
$   Create_Imake = "Y"
$   Do_Make = "Y"
$ Return
$!
$ Set_Sys_Options:
$   Create_Source = "Y"
$   Create_Imake = "Y"
$   Do_Make = "Y"
$ Return
$!
$Run_Make_File:
$   if F$SEARCH("ztimsfilt.imake") .nes. ""
$   then
$      vimake ztimsfilt
$      purge ztimsfilt.bld
$   else
$      if F$SEARCH("ztimsfilt.bld") .eqs. ""
$      then
$         gosub Imake_File
$         vimake ztimsfilt
$      else
$      endif
$   endif
$   if (primary .eqs. " ")
$   then
$      @ztimsfilt.bld "STD"
$   else
$      @ztimsfilt.bld "''primary'" "''secondary'"
$   endif
$ Return
$!#############################################################################
$Repack_File:
$ create ztimsfilt.repack
$ DECK/DOLLARS="$ VOKAGLEVE"
$ vpack ztimsfilt.com -
	-s ztimsfilt.c -
	-i ztimsfilt.imake
$ Exit
$ VOKAGLEVE
$ Return
$!#############################################################################
$Source_File:
$ create ztimsfilt.c
$ DECK/DOLLARS="$ VOKAGLEVE"
/*--------------------------------------------------------------------------*/
/*   c-language bridge to Timsfilt, which calls the cwave subroutine        */
/*   from the file timssubs.f.  Timsfilt is a simple interface to centwave  */
/*   that returns the filter and wavelen arrays explicitly instead of via   */
/*   fortran common blocks                                                  */


#include "xvmaininc.h"
#include "ftnbridge.h"
#include "ftnname.h"


int ztimsfilt(date, wave, filter, wavelen)
  int date;
  float wave[6], filter[6][158], wavelen[158];
{
  FTN_NAME(timsfilt)(&date, wave, filter, wavelen);

  return 1;
}
$ VOKAGLEVE
$ Return
$!#############################################################################
$Imake_File:
$ create ztimsfilt.imake

#define SUBROUTINE ztimsfilt

#define MODULE_LIST ztimsfilt.c

#define P3_SUBLIB

#define USES_C

$ Return
$!#############################################################################
