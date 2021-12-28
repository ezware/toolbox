/**
 * The first thing to know about are types. The available types in Thrift are:
 *
 *  bool        Boolean, one byte
 *  i8 (byte)   Signed 8-bit integer
 *  i16         Signed 16-bit integer
 *  i32         Signed 32-bit integer
 *  i64         Signed 64-bit integer
 *  double      64-bit floating point value
 *  string      String
 *  binary      Blob (byte array)
 *  map<t1,t2>  Map from one type to another
 *  list<t1>    Ordered list of one type
 *  set<t1>     Set of unique elements of one type
 *
 * Did you also notice that Thrift supports C style comments?
 */

// Just in case you were wondering... yes. We support simple C comments too.

//include "shared.thrift"

/**
 * Thrift files can namespace, package, or prefix their output in various
 * target languages.
 */

//namespace java tutorial
//namespace php tutorial

/**
 * Thrift lets you do typedefs to get pretty names for your types. Standard
 * C style here.
 */
//typedef i32 MyInteger

/**
 * Thrift also lets you define constants for use across languages. Complex
 * types and structs are specified using JSON notation.
 */
//const i32 INT32CONSTANT = 9853
//const map<string,string> MAPCONSTANT = {'hello':'world', 'goodnight':'moon'}

/**
 * You can define enums, which are just 32 bit integers. Values are optional
 * and start at 1 if not supplied, C style again.
 */
enum DLSTATE {
  ADDED = 1
  DOWNLOADING = 2,
  PAUSED = 3,
  DONE = 4,
}

/**
 * Structs are the basic complex data structures. They are comprised of fields
 * which each have an integer identifier, a type, a symbolic name, and an
 * optional default value.
 *
 * Fields can be declared "optional", which ensures they will not be included
 * in the serialized output if they aren't set.  Note that this requires some
 * manual management in some languages.
 */
struct dlinfo {
  1: i32 did,
  2: string filename,
  3: string url,
  4: DLSTATE state,
  5: i32 size,
  6: i32 progress,  //percent
  7: optional string location
}

/**
 * Structs can also be exceptions, if they are nasty.
exception InvalidOperation {
  1: i32 whatOp,
  2: string why
}
*/

/**
 * Download service
 */
service Download {
   /* return: download id */
   i32 add_dl(1:string url, 2:string filename),
   i32 del_dl(1:i32 did),

   i32 pause_dl(1:i32 did),
   i32 resume_dl(1:i32 did),

   /* return: dl count */
   list<dlinfo> get_dl_list(1:i32 maxcount),

   /* redownload a previous downloaded file */
   i32 redown(1:i32 did),

   /* default min delta is 5% */
   i32 get_progress(1:i32 did, 2:i32 mindelta)

   /**
    * This method has a oneway modifier. That means the client only makes
    * a request and does not listen for any response at all. Oneway methods
    * must be void.
    */
   //oneway void zip()
}
