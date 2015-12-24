/*

C wiki parser library and sample application.

Copyright (c) 2010, Mark Wharton
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

- Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

- Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

*/
#ifndef _WIKIPARSER_H                        /* duplication check */
#define _WIKIPARSER_H

#if defined(__cplusplus)
#define __WIKIPARSER_CLINKAGEBEGIN extern "C" {
#define __WIKIPARSER_CLINKAGEEND }
#else
#define __WIKIPARSER_CLINKAGEBEGIN
#define __WIKIPARSER_CLINKAGEEND
#endif
__WIKIPARSER_CLINKAGEBEGIN

#include <stdlib.h>
#if ! defined(__cplusplus)
#include <stdbool.h>
#endif
#include <assert.h>
#include <stdio.h>
#include <string.h>

#ifndef WIKIPARSERAPI
#define WIKIPARSERAPI /* nothing */
#endif

/* HTML 5 and Wiki Creole 1.0 references:

   http://www.w3.org/TR/html5/obsolete.html#non-conforming-features
   http://www.w3.org/TR/html5/text-level-semantics.html#usage-summary

   http://www.wikicreole.org/wiki/Creole1.0

   ./wiki2html -ab 4096 < wikicreole1.txt > wikicreole1.html

   -w wiki option

   Use a subset of wiki creole, enough to do the job...

   Wiki creole features not supported:
   - closing braces cannot be included in preformatted blocks
   - more restrictive use of whitespace
   - no free standing links
   - no image escape character
   - no image inside links
   - no link escape character
   - space required after single * and # list start

   -x wiki extensions option

   Wiki extensions: code (monospace), keyboard, sample code, 
                    subscript, superscript, underline, variable

   -m inline nowiki monospace option

   This option can be useful when the wiki extensions are not used.
   From the spec: "For inline nowiki text, wiki implementers can 
   decide whether to display this text regularly or in monospace." */

typedef void *WikiParser;

#define wikiParserGetUserData(parser) (*(void **)(parser))

enum WIKI_PARSER_ERROR {
	WIKI_PARSER_ERROR_UNKNOWN = -1,
	WIKI_PARSER_ERROR_NONE,
	/* Alphabetical order from here. */
	WIKI_PARSER_ERROR_BUFFER,
	WIKI_PARSER_ERROR_MEMORY,
	WIKI_PARSER_ERROR_PARSER,
	WIKI_PARSER_ERROR_PSTACK,
	WIKI_PARSER_ERROR_READER,
	WIKI_PARSER_ERROR_WRITER
};

enum WIKI_PARSER_TOKEN_TYPE {
	WIKI_PARSER_TOKEN_TYPE_NONE,
	/* Alphabetical order from here. */
	WIKI_PARSER_TOKEN_TYPE_BOLD,
	WIKI_PARSER_TOKEN_TYPE_CODE,
	WIKI_PARSER_TOKEN_TYPE_DEFINITIONDESC,
	WIKI_PARSER_TOKEN_TYPE_DEFINITIONLIST,
	WIKI_PARSER_TOKEN_TYPE_DEFINITIONTERM,
	WIKI_PARSER_TOKEN_TYPE_HEADING0, /* Not used directly; for calculations. */
	WIKI_PARSER_TOKEN_TYPE_HEADING1,
	WIKI_PARSER_TOKEN_TYPE_HEADING2,
	WIKI_PARSER_TOKEN_TYPE_HEADING3,
	WIKI_PARSER_TOKEN_TYPE_HEADING4,
	WIKI_PARSER_TOKEN_TYPE_HEADING5,
	WIKI_PARSER_TOKEN_TYPE_HEADING6,
	WIKI_PARSER_TOKEN_TYPE_HORIZONTALRULE,
	WIKI_PARSER_TOKEN_TYPE_IMAGE,
	WIKI_PARSER_TOKEN_TYPE_ITALIC,
	WIKI_PARSER_TOKEN_TYPE_KEYBOARD,
	WIKI_PARSER_TOKEN_TYPE_LINEBREAK,
	WIKI_PARSER_TOKEN_TYPE_LINK,
	WIKI_PARSER_TOKEN_TYPE_LISTITEM,
	WIKI_PARSER_TOKEN_TYPE_ORDEREDLIST,
	WIKI_PARSER_TOKEN_TYPE_PARAGRAPH,
	WIKI_PARSER_TOKEN_TYPE_PREFORMATTED,
	WIKI_PARSER_TOKEN_TYPE_SAMPLECODE,
	WIKI_PARSER_TOKEN_TYPE_SUBSCRIPT,
	WIKI_PARSER_TOKEN_TYPE_SUPERSCRIPT,
	WIKI_PARSER_TOKEN_TYPE_TABLE,
	WIKI_PARSER_TOKEN_TYPE_TABLEDATA,
	WIKI_PARSER_TOKEN_TYPE_TABLEHEADER,
	WIKI_PARSER_TOKEN_TYPE_TABLEROW,
	WIKI_PARSER_TOKEN_TYPE_TEXT,
	WIKI_PARSER_TOKEN_TYPE_UNDERLINE,
	WIKI_PARSER_TOKEN_TYPE_UNORDEREDLIST,
	WIKI_PARSER_TOKEN_TYPE_VARIABLE,
	WIKI_PARSER_TOKEN_TYPE_WIKINOWIKI,
	WIKI_PARSER_TOKEN_TYPE_WIKIPLACEHOLDER,
	WIKI_PARSER_TOKEN_TYPE_WIKIPLUGIN
};

#define WIKI_PARSER_BUFFER_SIZE 32768

typedef struct WikiParserBufferStruct {
	const char *data;
	size_t size;
} WikiParserBuffer, *WikiParserBufferPtr;

WikiParserBuffer defaultWikiParserBuffer = {
	NULL, WIKI_PARSER_BUFFER_SIZE
};

WikiParserBuffer emptyWikiParserBuffer = {
	NULL, 0
};

typedef struct WikiParserTokenStruct {
	enum WIKI_PARSER_TOKEN_TYPE type;
	bool state;
	int value;
	WikiParserBuffer *source;
	WikiParserBuffer *target;
	WikiParserBuffer *text;
} WikiParserToken, *WikiParserTokenPtr;

WikiParserToken emptyWikiParserToken = {
	WIKI_PARSER_TOKEN_TYPE_NONE, false, 0, NULL, NULL, NULL
};

typedef bool (*ReaderFunc)(void *userData, WikiParserBuffer *buffer, size_t *size);
typedef bool (*WriteTextFunc)(void *userData, WikiParserBuffer *text);
typedef bool (*WriteTokenFunc)(void *userData, WikiParserToken *token);

typedef struct WikiParserConfigStruct {
	/* Options */
	bool additions; /* Wiki creole additions flag. */
	bool blogstyle; /* Treat linebreaks as line breaks. */
	bool monospace; /* Inline nowiki monospaced flag. */
	/* Writers */
	WriteTextFunc writeText;
	WriteTokenFunc writeToken;
} WikiParserConfig, *WikiParserConfigPtr;

WikiParserConfig emptyWikiParserConfig = {
	false, false, false, NULL, NULL
};

#if !defined(NDEBUG)
extern int g_wikiParserStringCounter;
#endif

/* function prototypes */

WikiParser WIKIPARSERAPI createWikiParser(WikiParserConfig *config);
WikiParserBuffer WIKIPARSERAPI *createWikiParserBuffer(size_t size);
char WIKIPARSERAPI *createWikiParserString(const char *data, size_t size);
void WIKIPARSERAPI wikiParserBufferFree(WikiParserBuffer *buffer);
void WIKIPARSERAPI wikiParserConfigureOptions(WikiParser parser, bool additions, bool blogstyle, bool monospace);
void WIKIPARSERAPI wikiParserConfigureWriters(WikiParser parser, WriteTextFunc writeText, WriteTokenFunc writeToken);
void WIKIPARSERAPI wikiParserFree(WikiParser parser);
int WIKIPARSERAPI wikiParserGetCurrentLine(WikiParser parser);
enum WIKI_PARSER_ERROR WIKIPARSERAPI wikiParserGetErrorCode(WikiParser parser);
const char WIKIPARSERAPI *wikiParserGetErrorString(WikiParser parser);
bool WIKIPARSERAPI wikiParserParseStream(WikiParser parser, WikiParserBuffer *buffer, ReaderFunc reader, int blockMode);
bool WIKIPARSERAPI wikiParserParseString(WikiParser parser, char *string, int blockMode);
void WIKIPARSERAPI *wikiParserSetUserData(WikiParser parser, void *userData);
bool wikiParserStandardInputReader(void *userData, WikiParserBuffer *buffer, size_t *size);
char WIKIPARSERAPI *wikiParserStringAppend(char *string, const char *data, size_t size);
void WIKIPARSERAPI wikiParserStringFree(char *string);

/* library management */

// Release:	29 May 2014 - 0.0.8
//			* Capture additional closing characters for inline nowiki, placeholder, and plugin.

// Release:	07 December 2013 - 0.0.7
//			* Improved catch-all for longer text tokens.

// Release:	28 November 2012 - 0.0.6
//			* Fixed wiki plugin text size problem.

// Release:	26 October 2010 - 0.0.5
//			* Fixed mismatched error strings.
//			* Fixed problem with wikiParserStringAppend.

// Release:	23 October 2010 - 0.0.4
//			* Added buffer management and macro support for markers (e.g. parserMark(pipe)).
//			* Added experimental ragelstuff.h macros for handling ragel functions in a routine way.
//			* Added wikiParserStandardInputReader callback function.
//			* Fixed block mode test condition with table and definition list.
//			* Moved release notes from source file to header file.
//			* Removed the writer callback parameters.

// Release:	19 October 2010 - 0.0.3
//			* Added reader and writer callbacks for streaming in/out.
//			* Added functions for setting various config options.

// Release:	18 October 2010 - 0.0.2
//			* Improved the basic structure.

// Release:	15 October 2010 - 0.0.1
//			* Initial release for style discussion.

#define _WIKI_VERSION    "0.0.8"
#define _WIKI_LIBVER     101
#define _WIKI_FORMATVER  "1.0"

__WIKIPARSER_CLINKAGEEND
#endif                                   /* duplication check */

/* END OF FILE */
