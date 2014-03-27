# CS3071 - Compiler Design Lab 7

#### Contents

  1. [Project Specification](#projectspec)
  2. [Overview of features added in previous Labs](#overview)
    * [Constant Definitions](#constdef)
    * [Strings](#strings)
    * [Conditional Assignments](#cond)
    * [_For_ Loop Statements](#for)
  3. [Arrays](#array)
    * [Single Dimension](#single)
  4. [Record Structures](#record)
  5. [Switch Statements](#switch)
  6. [Extra Features](#extra)
    * [Struct "Clone"](#clone)
    * [Divide By Zero Check](#div)
  7. [Appendix](#app)

### <a name="projectspec"></a> Project Specification 

> In addition to the extensions you have already made to the attributed
translation grammar for the programming language Tastier over the past few
weeks to provide support for constant definitions, strings, conditional
assignment and for statements etc, make further modifications to the language
by adding support for arrays (multi dimensional) plus a new structured data
type such as a record, along with a switch statement, and add one extra
feature to the complier (such as run-time checking of array bounds or allowing
the use of parameters in procedure calls).

### <a name="overview"></a>Overview of features added in previous Labs

##### <a name="constdef"></a>Constant Definitions

In my compiler constants (if present) must be the first thing defined in the
in the program, before any variable, struct or process declarations. Constants
must be in the form:

    
     const constname := constvalue;     
    

where `constname` can be any valid symbol name and `constvalue` is an integer
value. Constants can only be defined as integers.

The way constants are implemented within the compiler is by adding them to an
Instruction stack which I have called `globalDeclarations`. When a constant is
declared each assembly instruction which would be associated in bringing this
constant into existance would be added to the `globalDeclarations` stack. When
a procedure is then declared the instructions which were in
`globalDeclarations` are added to the main `program` instruction stack. The
reason for this is so the declarations for the constants are entered _after_
the `Enter` assembly instruction is added as otherwise the constants would not
be accessable from within that procedure. This is done at the beginning of
each procedure to ensure that the constants are available to each procedure
which is declared.

##### <a name="strings"></a>Strings

All string functionality has been removed in this version of the compiler. The
reason for this is because in the previous lab where it was required of us to
add a string data type I hadn't managed to get it working correctly. What I
had in previous version was a type which would parse the string and add the
ascii value of each letter into memory. Because this is not useful in itself,
and because having a string type is not included in the marking scheme for
this lab, I decided to remove it for the sake of the code coherency.

##### <a name="cond"></a>Conditional Assignments

Conditional assignments must be in the form

    
    symbolname := condition ? resultIfTrue : resultIfFalse;
    

For example:

    
    int j;
    j := 10<30 ? 99 : 33;
    write j;
    
    int k, m;
    k := 1;
    m := 10;
    j := m = k ? 99 : 33;
    write j;
    
    /* 
     * Output: ["99","33"]
     */
    

These ternary operators work in much the same way as an if-else statement.

##### <a name="for"></a>_For_ Loop Statements

For loops follow a similar syntax to that described in the project
specifications for that Lab (as opposed to C syntax for example) i.e.

    
    for (initial action; update action; terminating condition){
        // Do something
    }
    

For example:

    
    int a;
    a := 0;
    
    int i;
    for(i:=0; i:=i+1; i<10){
        a := a+1;
    }   
    write a;
    
    /*  
     * Output: ["10"] 
     */  
    

For loops work by creating a temporary List of instructions `tempList` which
removes the update action from the the main `program` instruction list and
adds it at the very end of the for loop. This prevents the for loop from
exiting prematurely which it would if the update condition was left at the
beginning of the for loop.

### <a name="array"></a>Arrays

##### <a name="single"></a>Single Dimension

Arrays are declared in a similar way to other variables in my compiler. The
size must be declared when being initialzised but it does not need to be
filled with values intitially. Arrays can be declared in the following two
ways:

    
    int anArray[5];
    int anotherArray[3] := {1,2,3};
    

Arrays behave as expected when accessing and writing to a given index but one
limitation is that the index must be a single number so no symbol names or
expressions can be used as indexes. Arrays are only allowed for integer types
also, array of booleans are not implemented.

  
Within the compiler arrays symbols are differentiated by their type being +10
higher than those of single elements of the type. This allows to distinguish
if a symbol is an array when reading or writing from that symbol by simply
checking if it is greater or equal to 10. Doing a `mod 10` operation also
allows us to get the correct type of the array.

Space is then allocated by storing repeatedly adding 0 to a global address
until the size of the array is reached. In this way the array is initialzied
at zero and it ensures that no other `StoG` operations overwrite the space
allocated to the array.

Arrays are also given a seperate symbol list in addition to the ordinary
symbol table. The `Pointers` List is a list of Tuples in which the first Item
represents the array symbol, the second Item the arrays position in memory,
and the third Item the size of the array. When an array is created the
corresponding data is inserted in the pointers list so that it may be called
upon again to ensure that any array indexing does not go out of bounds of the
array.

When attempting to write to an array index the compiler first deals with the
symbol as it would normally, while taking note of the index value being
accessed. It then checks to see if Item3 (the type) of the symbol is greater
or equal than 10, which in the case of a array it will be. The compiler then
searches through the pointer list until it finds the corresponding array
symbol and then takes note of its address in memory and also its size from the
corresponding Tuple. If the index is greater or equal to the size at that
stage it throws an `Array index out of bounds` error otherwise it stores the
assigned value in the corresponding array index address.

Writing an array index works as expected.

**Example of array usage:**
    
    int anArray[3];
    anArray[2] := 11;     
    write anArray[2];
    
    int anotherArray[5] := {1,2,3,4,5}; 
    write anotherArray[4];
    
    /*  
     * Output: ["11","5"]
     */
    

### <a name="record"></a>Record Structures

Record structures in my compiler are based on the C `struct` declaration and
follow the following format for declaration:

    
    Struct structName {
        int aVariable;
        bool anotherVariable;
        // etc
    };
    

Structs can be declared at any position in the program but must be declared
before they are used otherwise the compiler will not be able to find the
corresponding symbols of the struct.

To create a new instance of a struct you simply do

    
    struct structname someName;
    

and to assign to struct variables you type

    
    someName.aVariable := 33; 
    

_Note that struct must be capitalised when declaring the struct initally but
lowercase when creating an instance of the struct._

Structs work by parsing the struct as usual adding each symbol to the symbol
table but prepending the structname to each of the variables of the struct to
avoid any symbol conflicts. For example in the case above the variable
`aVariable` would initially appear in the symbol table as
`structName.aVariable`.

When an instance of the struct is then created the compiler goes through a
modified version of the symbol `lookup` function which finds each symbol
associated with the struct, strips the original name of the struct from the
symbol and adds a new symbol with the new struct variable name prepended to
it. So in the example above the new symbol would be `someName.aVariable` and
would be accessed as is shown above.

**Example of struct usage**
    
    Struct myStruct {
        int i;
        int j;
        bool yea;
    };
    
    Main() {
        struct myStruct hello;
        hello.i := 10;
        write hello.i;
    
        /*
         * Output: ["10"]
         */
    }
    

### <a name="switch"></a>Switch Statements

Switch statments follow the common syntax of most programming languages which
is:

    
    switch(variable){
        case variable:
                //Do something
    
        case variable+n:
                //Do something else
                break;
    }
    

Fall-through is allowed in my switch statements if a break is not present.
Each switch statement must have at least one case.

Within the compiler switch statements work by first gathering the switch
condition into a temporary Instruction list `tempList` so that the condition
can be inserted for each case. It then goes through each case starting with
the first checking to see if the switch condition is equal to the case
variable, going through the code included in the case if they are equal,
jumping over it to the next case if not.

`break`'s are optional but if they are not present the program will jump over
the case comparison for the next case and execute the code included in that
case (i.e. fall through).

**Example switch statement:**
    
    int q;
    q := 1;
    
    switch(q){
        case 1:  write 1;
    
        case 2:  q:=2;
                 write q;
                 break;
    
        case 3:  write 99;
    }
    
    /*
     * Output: ["1","2"]
     */
    

### <a name="extra"></a>Extra Features

##### <a name="clone"></a>Struct "Clone"

One extra feature I added was an extra `clone` function which non-
destructively copies the variables of one struct into that of another. The
syntax for that is as follows:

    
    clone ( originalStruct , destinationStruct );
    

In each case the structs must be declared before the clone funciton is used.
They must also be of the same type, you cannot clone a struct of one type to
that of another.

Clone works by searching through the symbol table for each symbol associated
with the original structure and the destination structure, adding each symbol
to a temporary symbol list when they are found. It then goes through each
symbol and loads the value of the variable of the original struct and stores
it in the address associated with the destination structs corresponding
variable. If the compiler notices at any stage that the structs aren't of the
same type it will throw an error.

##### <a name="div"></a>Divide By Zero Check

Exactly what it says on the tin. This feature checks to see if the programmer
is attempting to divide by zero at compile time and throws an error if they
are.

  

### <a name="app"></a>Appendix

##### Test program including all of the implemented features

    
    program Test {
    
        const myConst := 1551;
    
        Struct myStruct {
            int i;
            int j;
            bool yea;
        };
    
        void Main() {
            // Struct example
            struct myStruct hello;
            hello.i := 10;
            write hello.i;
    
            /*
             * Output: ["10"]
             */
    
            // Clone example
            struct myStruct hiThere;
            clone(hello,hiThere);
            write hiThere.i;
    
            /*
             * Output: ["10"]
             */
    
            // Ternary operation example
            int j;
            j := 10<30 ? 99 : 33;
            write j;
    
            int k, m;
            k := 1;
            m := 10;
            j := m = k ? 99 : 33;
            write j;
    
            /*
             * Output: ["99","33"]
             */
    
    
            // For Loop example
            int a;
            a := 0;
            int i;
            for(i:=0; i:=i+1; i<10){
                a := a+1;
    
            /*
             * Output: ["10"]
             */
    
            // Array example
            int anArray[3];
            anArray[2] := 11;
            write anArray[2];
    
            int anotherArray[5] := {1,2,3,4,5};
            write anotherArray[4];
    
            /*
             * Output: ["11","5"]
             */
    
            // Switch example
            int q;
            q := 1;
    
            switch(q){
                case 1:     write 1;
    
                case 2:     q:=2;
                            write q;
                            break;
    
                case 3:     write 99;
            }
    
            /*
             * Output: ["1","2"]
             */
    
            // Const example
            write myConst;
    
            /*
             * Output: ["1551"]
             */
        }
    
    }
    

Which produces the output:

    
    ["10","10","99","33","10","11","5","1","2","1551"]
    
