#include <stdlib.h>
#include <stdio.h>
#include <stdbool.h>
#include <string.h>
#include <unistd.h>
#include <pwd.h>
#include <unistd.h>
#include <sys/ioctl.h>
#include <sys/io.h>
#include <limits.h>

#define ESC "\033"
#define CLEAR "[0"
#define FG "[38;5;"
#define BG "[48;5;"
#define END "m"

#define bg set_bg( background )

#define fgl set_fg( low )
#define fgm set_fg( mid )
#define fgh set_fg( high )

const char sep_right_char[]    = { 0xEE, 0x82, 0xB0, 0x00 }; // \uE0B0 | 
const char sep_left_char[]     = { 0xEE, 0x82, 0xB2, 0x00 }; // \uE0B2 | 
const char suspension_char[]   = { 0xE2, 0x8B, 0xAF, 0x00 }; // \u22EF | ⋯
const char home_char[]         = { 0xE2, 0x8C, 0x82, 0x00 }; // \u2302 | ⌂
const char line_char[]         = { 0xE2, 0x94, 0x80, 0x00 }; // \u2500 | ─
const char upper_left_char[]   = { 0xE2, 0x95, 0xAD, 0x00 }; // \u256D | ╭
const char lower_left_char[]   = { 0xE2, 0x95, 0xB0, 0x00 }; // \u2570 | ╰
const char less_than_char[]    = { 0xE2, 0x9D, 0xAE, 0x00 }; // \u276E | ❮
const char greater_than_char[] = { 0xE2, 0x9D, 0xAF, 0x00 }; // \u276F | ❯

static const int char_size = sizeof( char );

static void nl ( void ) { printf( "\n" ); }

static void reset ( void ) { printf( "%s%s%s", ESC, CLEAR, END ); }

static void set_bg ( int col ) { printf( "%s%s%d%s", ESC, BG, col, END ); }

static void set_fg ( int col ) { printf( "%s%s%d%s", ESC, FG, col, END ); }

static void spc ( void ) { printf( " " ); }

static int line_1_start () {
    printf( "%s%s", upper_left_char, less_than_char );
    return 2;
}

static void line_2_start ( void ) {
    printf( "%s%s%s ", lower_left_char, line_char, greater_than_char );
}

static int start_prompt ( int col ) {
    set_fg( col );
    printf( "%s", sep_left_char );
    return 1;
}

static void sep ( void ) {
    printf( "%s", sep_right_char );
}

static int get_int_from_uli ( unsigned long int value ) {
    int len =! value;
    while( value ) { len++; value /= 10; }
    return len;
}

static bool starts_with ( const char *a, const char *b ) {
    if ( strncmp( a, b, strlen( b ) ) == 0 ) return 1;
    return 0;
}

static char* concat ( const char *a, const char *b ) {
    char *result = malloc( strlen( a ) + strlen( b ) + 1 );
    strcpy( result, a );
    strcat( result, b );
    return result;
}

static char* str_replace ( char *orig, char *rep, const char *with) {
    char *res; char *ins; char *tmp;
    int len_rep; int len_with; int len_front;
    int count;

    if ( !orig || !rep ) { return NULL; }
    len_rep = strlen( rep );

    if ( len_rep == 0 ) { return NULL; }
    if ( !with ) { with = ""; }
    len_with = strlen( with );

    ins = orig;
    for ( count = 0; tmp = strstr( ins, rep ); ++count ) {
        ins = tmp + len_rep;
    }

    tmp = res = malloc( strlen( orig ) + ( len_with - len_rep ) * count + 1 );

    if ( !res ) { return NULL; }
    while ( count-- ) {
        ins = strstr( orig, rep );
        len_front = ins - orig;
        tmp = strncpy( tmp, orig, len_front ) + len_front;
        tmp = strcpy( tmp, with ) + len_with;
        orig += len_front + len_rep;
    }
    strcpy( tmp, orig );
    return res;
}

static int count_substring ( char string[], char substring[] ) {
    int subcount = 0;
    size_t sub_len = strlen( substring );
    if ( !sub_len ) { return 0; }

    for ( size_t i = 0; string[ i ]; ) {
        size_t j = 0;
        size_t count = 0;
        while (
            string[ i ] &&
            string[ j ] &&
            string[ i ] == substring[ j ]
        ) { count++; i++; j++; }
        if (count == sub_len) { subcount++; count = 0; }
        else { i = i - j + 1; }
    }
    return subcount;
}

static int uid ( struct passwd *passwd ) {
    unsigned long uid;
    int uid_length;
    uid = ( unsigned long ) passwd->pw_uid;
    uid_length = get_int_from_uli(  uid );
    printf( "%lu", uid );
    return uid_length;
}

static int gid ( struct passwd *passwd ) {
    unsigned long gid;
    int gid_length;
    gid = ( unsigned long ) passwd->pw_uid;
    gid_length = get_int_from_uli(  gid );
    printf( "%lu", gid );
    return gid_length;
}

static int id ( int background, int next_background,
        int low, int mid, int high, struct passwd *passwd ) {
    int id_length = 9; // I + D + | + : + u + | + g + : + sep
    bg; fgm; printf( "ID" );
    bg; fgl; printf( "|" ); bg; fgm; printf( "u:" );
    bg; fgh; id_length += uid( passwd );
    bg; fgl; printf( "|" ); bg; fgm; printf( "g:" );
    bg; fgh; id_length += gid( passwd );
    set_bg( next_background ); set_fg( background ); sep();
    return id_length;
}

static int username ( struct passwd *passwd ) {
    char *username;
    username=( char * )malloc( 32 * char_size );
    username = passwd->pw_name;
    int username_length;
    username_length = strlen( username );
    printf( "%s", username );
    return username_length;
}

static int hostname ( struct passwd *passwd ) {
    char *hostname;
    hostname=( char * )malloc( 1024 * char_size );
    gethostname( hostname, 1024 * char_size );
    int hostname_length;
    hostname_length = strlen( hostname );
    printf( "%s", hostname );
    return hostname_length;
}

static int user_and_host ( int background, int next_background,
        int low, int mid, int high, struct passwd *passwd ) {
    int user_and_host_length = 6; // spc+spc+@+spc+spc+sep
    bg; fgh; spc(); user_and_host_length += username( passwd );
    bg; fgl; printf( "%s", " @ " );
    bg; fgm; user_and_host_length += hostname( passwd ); spc();
    set_bg( next_background ); set_fg( background ); sep();
    return user_and_host_length;
}

static int shell ( struct passwd *passwd ) {
    char *shell;
    shell=( char * )malloc( 255 * char_size );
    shell = passwd->pw_shell;
    char *token = strtok( shell, "/" );
    while( token != NULL ) {
        shell = token;
        token = strtok( NULL, "/" );
    }
    int shell_length;
    shell_length = strlen( shell );
    printf( "%s", shell );
    return shell_length;
}

static int current_shell ( int background, int next_background,
        int low, int mid, int high, struct passwd *passwd ) {
    int current_shell_length = 3; // spc+spc+sep
    bg; fgh; spc(); current_shell_length += shell( passwd ); spc();
    set_bg( next_background ); set_fg( background ); sep();
    return current_shell_length;
}

static int current_working_dir ( int background, int next_background,
        int low, int mid, int high, struct passwd *passwd,
        int remaining, int total, int offset ) {

    bool is_wsl_home = false;
    bool is_win_home = false;

    char *username; username = ( char * )malloc( 33 * char_size );
    username = passwd->pw_name;
    char cwd [ PATH_MAX ];
    getcwd( cwd, sizeof( cwd ) );
    char *home; home = ( char * )malloc( 7 * char_size );
    home="/home/";
    char *homedir; homedir = ( char * )malloc( ( PATH_MAX + 1 ) * char_size );
    homedir = concat( home, username );

    char *dir; dir = ( char * )malloc( PATH_MAX );
    int cwd_length;

    if ( starts_with( cwd, homedir ) ) {
        is_wsl_home = true;
        dir = str_replace( cwd, homedir, "" );
    } else {
        dir = cwd;
    }

    cwd_length = strlen( dir );
    char *path; path = ( char * )malloc( ( cwd_length + 1 ) * char_size );
    int dirs; dirs = count_substring( dir, "/" );

    if ( cwd_length > remaining && dirs > 2) {

        char *p; p = ( char * )malloc( 257 * char_size );
        p = strtok( dir, "/" );

        char arr[ dirs ][ 256 ];

        int i = 0;

        while( p != NULL ) {
            strcpy( arr[ i++ ],  p );
            p = strtok( NULL, "/" );
        }

        path = concat( "/", arr[ 0 ] ); path = concat( path, "/" );
        path = concat( path, arr[ 1 ] );

        i = 2;
        while( remaining - ( offset + 1 ) < cwd_length ) {
            char *temp; temp = ( char * )malloc( 2 * char_size );
            strncpy( temp, arr[ i ], 1);
            temp = concat( "/", temp ); path = concat( path, temp );
            path = concat( path, suspension_char );
            int l = strlen( arr[ i++ ] );
            cwd_length += -l +2;
            free( temp );
        }
        while( i < dirs ) {
            path = concat( path, "/" );
            path = concat( path, arr[ i++ ] );
        }

    } else {

        strcpy( path, dir );

    }

    bg; spc(); cwd_length++;

    if ( is_wsl_home ) {
        set_fg( 81 );
        printf( "%s", home_char );
        cwd_length++;
    }

    fgh; printf( "%s ", path ); cwd_length++;

    while ( cwd_length < remaining - offset ) { spc(); cwd_length++; }

    set_bg( next_background ); set_fg( background ); sep();
    remaining -= cwd_length;
    return cwd_length;
}

static int draw_prompt ( int total_columns, struct passwd *passwd ) {
    int current_size = 0;
    int columns_remaining;
    current_size += line_1_start();
    current_size += start_prompt( 16 );
    current_size += id ( 16, 26, 235, 240, 245, passwd );
    current_size += user_and_host( 26, 19, 234, 232, 16, passwd );
    current_size += current_shell( 19, 235, 240, 244, 248, passwd );

    columns_remaining = total_columns - current_size;

    current_size += current_working_dir(
        235, 0, 21, 248, 250, passwd, columns_remaining, total_columns, 0
    );

    columns_remaining = total_columns - current_size;

    reset(); nl();
    line_2_start();
    return columns_remaining;
}

int main () {

    struct winsize w;
    int remaining;
    ioctl( STDOUT_FILENO, TIOCGWINSZ, &w );

    struct passwd *passwd;
    passwd = getpwuid( getuid() );

    remaining = draw_prompt( w.ws_col - 1, passwd );
    return 0;

}
