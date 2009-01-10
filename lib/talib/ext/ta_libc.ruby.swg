/****************************************************************************/
/* File : ta_libc.ruby.swg
 * Ruby typemaps for all TA interfaces
 */
/* Adittional typemap not found in the standard set *************************/

/* Some TA functions operate on (return) string tables
 * being (pointers to) arrays of pointers to char arrays
 * and having a size field.
 * They are being converted to native Ruby lists of strings.
 */

%inline %{
  #include "ta-lib/ta_libc.h"
  #include "rb_gsl_array.h"
%}

#ifdef TA_ABSTRACT
%define STRING_TABLE(TYPE, SIZE_FIELD)

%typemap(in,numinputs=0) TYPE** (TYPE *temp = 0)
    "$1 = &temp;"

%typemap(argout) TYPE**
{
    /* Copy the strings from **$1 to a Ruby array */
    if ( *$1 && (*$1)->SIZE_FIELD > 0) {
        int new_items = argvi + (*$1)->SIZE_FIELD;
        unsigned int elem;
        if (new_items > items) {
            EXTEND(sp,(new_items-items));
        }
        for (elem = 0;  elem < (*$1)->SIZE_FIELD;  elem++) {
            ST(argvi) = sv_newmortal();
            if ((*$1)->string[elem]) {
                sv_setpv((SV*)ST(argvi++), (char *) (*$1)->string[elem]);
            } else {
                sv_setsv((SV*)ST(argvi++), &PL_sv_undef);
            }
        }
    }
    $symnameFree(*$1);
}

/* we don't want just wrapper classes around */
%ignore TYPE;

%enddef /* STRING_TABLE */



/* Some string tables are not dynamically created
 * but defined at compilation time.
 * They must not be deallocated and use only one indirection.
 */
%define CONST_STRING_TABLE(TYPE, SIZE_FIELD)

%typemap(out) TYPE*
{
    /* Copy the strings from *$1 to a Ruby array */
    if ( $1->SIZE_FIELD > 0) {
        int new_items = argvi + $1->SIZE_FIELD;
        unsigned int elem;
            if (new_items > items) {
                EXTEND(sp,(new_items-items));
            }
        for (elem = 0;  elem < $1->SIZE_FIELD;  elem++) {
            ST(argvi) = sv_newmortal();
            if ($1->string[elem]) {
                sv_setpv((SV*)ST(argvi++), (char *) $1->string[elem]);
            } else {
                sv_setsv((SV*)ST(argvi++), &PL_sv_undef);
            }
        }
    }
}

/* we don't want just wrapper classes around */
%ignore TYPE;

%enddef /* CONST_STRING_TABLE */


/* Some other string tables are flat, i.e. there is only one string pointer
 * and all strings (fixed length) are one after another.
 */
%define STRING_BUFFER(TYPE, SIZE_FIELD, LEN_FIELD)

%typemap(in,numinputs=0) TYPE** (TYPE *temp = 0)
    "$1 = &temp;"

%typemap(argout) TYPE**
{
    /* Copy the strings from **$1 to a Ruby array */
    if ( *$1 && (*$1)->SIZE_FIELD > 0) {
        int new_items = argvi + (*$1)->SIZE_FIELD;
        unsigned int elem;
        if (new_items > items) {
            EXTEND(sp,(new_items-items));
        }
        for (elem = 0;  elem < (*$1)->SIZE_FIELD;  elem++) {
            ST(argvi) = sv_newmortal();
            sv_setpv((SV*)ST(argvi++), (char *) (*$1)->buffer+(elem*(*$1)->LEN_FIELD));
        }
    }
    $symnameFree(*$1);
}

/* we don't want just wrapper classes around */
%ignore TYPE;

%enddef /* STRING_BUFFER */



/* Handles are created and released only by appropriate calls to TA-Lib functions
 * They have no accessible fields
 * To obtain a handle in Ruby, use references
 * Example:
 *   $retCode = TA_HandleAlloc(\$handle);
 *   $retCode = TA_HandleFree($handle);
 *
 * However, for all TA handles, Ruby shadow classes are defined, simplifying
 * creaction and destruction.
 */
%define HANDLE(TYPE, NAME)

%typemap(in) TYPE **NAME($*1_ltype temp)
{
    SV *tempsv;
    if (!SvROK($input)) {
        SWIG_croak("Expected a reference as argument $argnum of $symname");
    }
    tempsv = SvRV($input);
    if (SWIG_ConvertPtr(tempsv, (void **) &temp, $*1_descriptor, 0) < 0) {
        SWIG_croak("Type error in argument $argnum of $symname. Expected $*1_mangle");
    }
    if (temp) {
        SWIG_croak("Expected a reference to undef variable as argument $argnum of $symname");
    }
    $1 = &temp;
}

%typemap(argout) TYPE **NAME
{
    SV *tempsv;
    tempsv = SvRV($input);
    SWIG_MakePtr(tempsv, (void *) *$1, $*1_descriptor, SWIG_SHADOW);
}

/* Don't create default constructors/destructors  */
%nodefault TYPE;

%enddef /* HANDLE */



/* For const handles returned, Ruby refs are used too, but the objects need not be created */
/* (const handles are used in ta_abstract) */
%define CONST_HANDLE(TYPE, NAME)

%typemap(in) const TYPE **NAME($*1_ltype temp = 0)
{
    $1 = &temp;
    if (!SvROK($input)) {
        SWIG_croak("Expected a reference as argument $argnum of $symname");
    }
}

%typemap(argout) const TYPE **NAME
{
    SV *tempsv;
    tempsv = SvRV($input);
    SWIG_MakePtr(tempsv, (void *) *$1, $*1_descriptor, SWIG_SHADOW);
}

/* Don't create default constructors/destructors.
 */
%nodefault TYPE;

%enddef /* CONST_HANDLE */




/* typemaps for TA objects like TA_History */

/* Objects are created as argout (just to be different than handles ;-)
 * Example:
 * @res = TA_HistoryAlloc($udb, $history_param);
 * $history = $res[1] if $res[0] == $TA_SUCCESS;
 *
 * Clumsy, huh?
 * However in practice, you will use 'new' anyway...
 */

%define OBJECT(TYPE, NAME)

%typemap(in,numinputs=0) TYPE **NAME($*1_ltype temp = 0)
        "$1 = &temp;";

%typemap(argout) TYPE **NAME
%{
    if (*$1) {
        if (argvi >= items) {
            EXTEND(sp,1);
        }
        $result = sv_newmortal();
        SWIG_MakePtr($result, (void *) *$1, $*1_descriptor, SWIG_SHADOW|SWIG_OWNER);
        argvi++;
    }
%}

/* Don't create default constructors/destructors.
 */
%nodefault TYPE;

%enddef  /* OBJECT */


/* typemaps for "array objects," that is, objects holding arrays as member data,
 * like TA_History, TA_PMArray...
 */

%define ARRAY_OBJECT(TYPE, SIZE_FIELD)

/* Each array object saves its size in array_size
 * This will later be needed when acessing the member arrays
 * This typemap does not perform a conversion, that's why it
 * cannot be type 'in'.
 */
%typemap(check) TYPE* (unsigned int array_size)
    "array_size = ($1 != NULL)? ($1->SIZE_FIELD) : 0;"

/* SIZE_FIELD must not be modified, otherwise segmentation fault may occur */
%immutable SIZE_FIELD;

%enddef /* ARRAY_OBJECT */

/* Is that all?  Not really.  Array objects may have various number
 * of member arrays, of various types.  The following ARRAY typemaps
 * serve to access individual member arrays.
 * But how to figure out how many elements the arrays have?
 * This and the following three typemaps rely upon the encompassing structure
 * creating a local variable array_size.
 * That's why each encompassing structure has to be defined as ARRAY_OBJECT.
 * If forgotten to define it, a compile error will occur.
 */
%typemap(out) const TA_Real *ARRAY
{
    AV *av;
    unsigned int idx = 0;
    SV *sv;

    av = newAV();
    av_extend(av, array_size1-1);
    for (idx = 0; idx < array_size1 ; idx++) {
        sv = newSVnv($1[idx]);
        if (av_store(av, idx, sv) == 0) SvREFCNT_dec(sv);
    };
    $result = sv_2mortal(newRV_noinc((SV*)av));
    argvi++;
}

%typemap(out) const TA_Integer *ARRAY
{
    AV *av;
    SV *sv;
    unsigned int idx = 0;

    av = newAV();
    av_extend(av, array_size1-1);
    for (idx = 0; idx < array_size1 ; idx++) {
        sv = newSViv($1[idx]);
        if (av_store(av, idx, sv) == 0) SvREFCNT_dec(sv);
    };
    $result = sv_2mortal(newRV_noinc((SV*)av));
    argvi++;
}


/* There are also arrays of other types used.
 * They will be defined by the following typemap macro.
 */
%define MEMBER_ARRAY(TYPE)

%typemap(out) const TYPE *ARRAY
{
    AV *av;
    SV **svs;
    unsigned int idx = 0;

    /* this is not the most efficient way of creating an array
     * it creates much too many mortals
     * I have cloned it from SWIG example but a better way is in
     * the typemaps above
     * TODO: optimize it here
     */
    svs = (SV **) malloc(array_size1 * sizeof(SV *));
    for (idx = 0; idx < array_size1 ; idx++) {
        svs[idx] = sv_newmortal();
        SWIG_MakePtr((SV*)svs[idx], (void *) &$1[idx], $1_descriptor, SWIG_SHADOW);
    };
    av =  av_make(array_size1,svs);
    free(svs);
    $result = sv_2mortal(newRV_noinc((SV*)av));
    argvi++;
}

%enddef /* MEMBER_ARRAY */



/* Some member arrays contain just pointers to objects,
 * not the objects themselves.
 * Therefore the typemap has to be modified slightly.
 */
%define MEMBER_PTRARRAY(TYPE)

%typemap(out) const TYPE **ARRAY
{
    AV *av;
    SV **svs;
    unsigned int idx = 0;

    /* as in the previous case
     * this is not the most efficient way of creating an array
     * it creates much too many mortals
     * I have cloned it from SWIG example but a better way is in
     * the typemaps for TA_Integer and TA_Real
     * TODO: optimize it here
     */
    svs = (SV **) malloc(array_size1 * sizeof(SV *));
    for (idx = 0; idx < array_size1 ; idx++) {
        svs[idx] = sv_newmortal();
        SWIG_MakePtr((SV*)svs[idx], (void *) $1[idx], $*1_descriptor, SWIG_SHADOW);
    };
    av =  av_make(array_size1,svs);
    free(svs);
    $result = sv_2mortal(newRV_noinc((SV*)av));
    argvi++;
}

%enddef /* MEMBER_PTRARRAY */



/* typemaps for ta_common ***************************************************/


/* typemaps for TA_FatalReportToBuffer */

%typemap(default) ( char *buffer, unsigned int bufferSize )
{
    $1 = NULL;
    $2 = TA_FATAL_ERROR_BUF_SIZE; /* default */
}

%typemap(in) ( char *buffer, unsigned int bufferSize )
{
    $2 = ($2_ltype) SvUV($input);
}

%typemap(check) ( char *buffer, unsigned int bufferSize )
{
    $1 = ($1_ltype) malloc($2);
}

%typemap(argout) ( char *buffer, unsigned int bufferSize )
{
    if (argvi >= items) {
        EXTEND(sp,1);
    }
    $result = sv_newmortal();
    sv_setpv($result, $1);
    argvi++;
}

%typemap(freearg) ( char *buffer, unsigned int bufferSize )
{
    free($1);
}


#endif

/* typemaps for ta_func *****************************************************/

/* The following typemaps are defined:
    START_IDX, END_IDX
    IN_ARRAY
    OPT_INT, OPT_REAL
    BEG_IDX, OUT_SIZE,
    OUT_ARRAY
*/

/* START_IDX and END_IDX are always the first two arguments of all functions.
X * They create two local (auto) variables, startIdx1 and endIdx2
 * Other typemaps depend on them to allocate properly sized C arrays.
 */
%typemap(in) int START_IDX (int startIdx)
{
  $1 = (int) FIX2INT($input);
  if ($1 < 0) $1 = 0;                 /* ensure valid array range */
}

%typemap(in) int END_IDX (int endIdx)
{
  $1 = (int) FIX2INT($input);
  if ($1 < arg1) $1 = arg1;  /* ensure valid array range */
}

/* Input arrays are passed by references, otherwise they would loose
 * their identity.  Besides, it is more effiecient.
 * As it is implemented now, startIdx and endIdx values overrule the actual
 * array size; eventual missing elements are created and set to zero.
 */
%typemap(in) const double *IN_ARRAY, const float *IN_ARRAY
{
  size_t array_size = arg2 - arg1 +1;

  if (! VECTOR_P($input) )
    SWIG_croak("Expected an GSL::Vector $argnum of $symname");
    size_t stride;
    size_t len;

    $1_ltype vptr = get_vector_ptr($input, &stride, &len);

    if ( len < array_size )
      SWIG_croak("Range of input indexes exceeds size of Vector");
    $1 = vptr;
}

%typemap(default) double OPT_REAL
    "$1 = TA_REAL_DEFAULT;"

%typemap(default) int OPT_INT
    "$1 = 2;"

%typemap(in) double OPT_REAL
  "$1 = NUM2DBL($input);"

/* outBegIdx is handled just as a regular OUTPUT parameter, except that
 * if the function failed, undef is returned
 */
%typemap(arginit) int *BEG_IDX
    "int outIndex = 0;";

%typemap(arginit) double* OUT_ARRAY
    "gsl_vector* $1_name = 0;"

%typemap(arginit) float* OUT_ARRAY
    "gsl_vector_float* $1_name = 0;"

%typemap(arginit) int* OUT_ARRAY
    "gsl_vector_int* $1_name = 0;"

%typemap(in,numinputs=0) int *BEG_IDX(int temp = 0)
    "$1 = &outIndex;";

%typemap(argout, fragment="output_helper") int *BEG_IDX
{
  $result = output_helper( $result, INT2NUM(outIndex) );
}


/* Parameter outNbElement is an out value, but is not passed back to Ruby.
 * It is used to construct OUT_ARRAY of proper length.
 * Its position within the parameter list varies, so we cannot use
 * local variables declared in the same way as for startIdx and endIdx.
 * Taking advantage of that 'arginit' typemaps are the very first ones in
 * the wrapper function, we declare an explicitly named local variable.
 */
%typemap(arginit) int *OUT_SIZE
    "int outNbElement = 0;";

%typemap(in,numinputs=0) int *OUT_SIZE
    "$1 = &outNbElement;";

/* As last, output arrays come.  Since they are only output, numinputs=0 is
 * given so that they do not have to be provided in the function call from Ruby.
 * However, in such case, they are placed at the very top of the wrapper
 * function, before other inputs (SWIG bug?), making startIdx and endIdx
 * not accessible in the 'in' typemap.
 * Therefore the 'in' typemap does not generate any code,
 * but the array allocation is done in the 'check' typemap.
 */
%typemap(in,numinputs=0) double *OUT_ARRAY, float *OUT_ARRAY, int *OUT_ARRAY
    "/* $1 ignored on input */";

%typemap(check) double *OUT_ARRAY
{
    size_t array_size = arg2 - arg1 + 1;
    $1_name = gsl_vector_calloc(array_size);
    $1 = $1_name->data;
}
%typemap(check) float *OUT_ARRAY
{
    size_t array_size = arg2 - arg1 + 1;
    $1_name = gsl_vector_float_calloc(array_size);
    $1 = $1_name->data;
}
%typemap(check) int *OUT_ARRAY
{
    size_t array_size = arg2 - arg1 + 1;
    $1_name = gsl_vector_int_calloc(array_size);
    $1 = $1_name->data;
}

/*
** On output we first check if the output array is the same size and shape
** as the gsl vector that was provided. If it is, we just wrap it up in a ruby object
** and return it along with starting index (which in this case will be zero). If the
** array is of different type or shape, we allocate a new one of the outNbElemnt size
** and copy the sub-vector into the output vector.
 */
%typemap(argout, fragment="output_helper") double *OUT_ARRAY
{
  if ( result == TA_SUCCESS && outNbElement > 0) {
    if ( (arg2-arg1+1) == outNbElement && outIndex == 0 ) {
      $result = output_helper( $result, Data_Wrap_Struct(cgsl_vector, 0, gsl_vector_free, $1_name));
    } else {
      gsl_vector* ogv = gsl_vector_alloc(outNbElement);
      gsl_vector_view iview = gsl_vector_subvector($1_name, 0, outNbElement);
      gsl_vector_memcpy(ogv, &iview.vector);
      gsl_vector_free($1_name);
      $result = output_helper($result, Data_Wrap_Struct(cgsl_vector, 0, gsl_vector_free, ogv));
    }
  } else {
    gsl_vector_free($1_name);
    SWIG_exception(SWIG_RuntimeError, "Error encountered in $sysname");
  }
}

%typemap(argout) float *OUT_ARRAY
{
  SWIG_croak("Float return types not implement yet ($symname)");
}

%typemap(argout, fragment="output_helper") int *OUT_ARRAY
{
  if ( result == TA_SUCCESS && outNbElement > 0) {
    if ( (arg2-arg1+1) == outNbElement && outIndex == 0 ) {
        $result = output_helper( $result, Data_Wrap_Struct(cgsl_vector, 0, gsl_vector_int_free, $1_name));
      } else {

        gsl_vector_int* ogv = gsl_vector_int_alloc(outNbElement);
        gsl_vector_int_view iview = gsl_vector_int_subvector($1_name, 0, outNbElement);
        gsl_vector_int_memcpy(ogv, &iview.vector);
        gsl_vector_int_free($1_name);
        $result = output_helper( $result, Data_Wrap_Struct(cgsl_vector, 0, gsl_vector_int_free, ogv));
      }
    } else {
      gsl_vector_int_free($1_name);
      SWIG_exception(SWIG_RuntimeError, "Error encountered in $sysname");
  }
}

%apply double *OUT_ARRAY { double *OUT_ARRAY1 };
%apply double *OUT_ARRAY { double *OUT_ARRAY2 };
%apply double *OUT_ARRAY { double *OUT_ARRAY3 };

/* It is safer to have a separate typemap for cleanup rather than doing it
 * at the end of the 'argout' typemap.
 * If there were SWIG_croak() between the inlined typemap 'check' and
 * the typemap 'argout', memory leak could occur.
 * The code of the typemap 'freearg' will always be executed.
 */

/* This is no longer neccessary as ruby gsl takes care dealloc during GC
%typemap(freearg) double *OUT_ARRAY, float *OUT_ARRAY, int *OUT_ARRAY
    "free($1);";
*/



/* typemaps for ta_abstract *************************************************/

/* The field 'dataSet' is a tricky one; it has to be recast from const void*
 * to something sensible depending on the value of 'type'
 */
%typemap(out) const void *dataSet %{
    if ($1) {
        swig_type_info *retType = NULL;

        switch (arg1->type) {
            case TA_OptInput_RealRange    : retType = SWIGTYPE_p_TA_RealRange;    break;
            case TA_OptInput_RealList     : retType = SWIGTYPE_p_TA_RealList;     break;
            case TA_OptInput_IntegerRange : retType = SWIGTYPE_p_TA_IntegerRange; break;
            case TA_OptInput_IntegerList  : retType = SWIGTYPE_p_TA_IntegerList;  break;
        }
        if (retType) {
            $result = sv_newmortal();
            SWIG_MakePtr($result, (void *) $1, retType, SWIG_SHADOW);
            argvi++;
        }
    }
%}

/****************************************************************************/
