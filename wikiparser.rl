/*

C wiki parser library and sample application.

Copyright (c) 2010, Mark Wharton
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

- Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

- Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

*/
//======================================================================
//
// Author:	Mark Wharton
//
// Date:	29 May 2014
//
// Title:	Wiki Parser
//
// Version:	0.0.8
//
// Topic:	Introduction
//			**Features**
//			
//			Supports [[http://www.wikicreole.org/wiki/Creole1.0|Creole 1.0]] with the following limitations:
//			* Closing braces cannot be included in preformatted blocks
//			* More restrictive use of whitespace
//			* No free standing links
//			* No image escape character
//			* No image inside links
//			* No link escape character
//			* Space follows list start * and #
//			* Unix line breaks (LF) no Windows (CRLF)
//			
//			**Dependencies**
//			
//			* [[http://www.complang.org/ragel/|ragel]] for building wikiparser library
//			
//			**Installation**
//			
//			Run the configuration script.
//			{{{
//			  ./configure
//			}}}
//			
//			Build the library and programs.
//			{{{
//			  make
//			}}}
//			
//			Install the library and programs.
//			{{{
//			  sudo make install
//			}}}
//			
//			**Using the Wiki Application**
//			
//			{{{
//			  Usage: wiki2html [-a] [-b bufferSize] [-m] < input.text > output.html
//			
//			  -a enable additional features specified in the Creole 1.0 Additions
//			  -m flag monospace in the WIKI_PARSER_TOKEN_TYPE_WIKINOWIKI token
//			}}}
//			
//			**Using the Wiki Library**
//			
//			{{{
//			  gcc -I/usr/local/include wikiapp.c -o wikiapp -L/usr/local/lib -lwikiparser
//			}}}
//			
//			**Sample Wiki Application**
//			
//			{{{
//			#include "wikiparser.h"
//			
//			bool wikiTextWriter(void *userData, WikiParserBuffer *text)
//			{
//			  return fwrite(text->data, text->size, 1, stdout) >= 0;
//			}
//			
//			bool wikiTokenWriter(void *userData, WikiParserToken *token)
//			{
//			  bool error = false;
//			  if (token->text)
//			    error = fwrite(token->text->data, token->text->size, 1, stdout) < 0;
//			  return !error;
//			}
//			
//			int main(int argc, char **argv)
//			{
//			  WikiParser parser = createWikiParser(NULL);
//			  if (parser) {
//			    wikiParserConfigureWriters(parser, wikiTextWriter, wikiTokenWriter);
//			    WikiParserBuffer *buffer = createWikiParserBuffer(WIKI_PARSER_BUFFER_SIZE);
//			    if (buffer) {
//			      if (!wikiParserParseStream(parser, buffer, NULL, 0)) {
//			        fprintf(stderr, "Error: parser error: %d %s (line %d)\n", 
//			          wikiParserGetErrorCode(parser), wikiParserGetErrorString(parser), 
//			          wikiParserGetCurrentLine(parser));
//			        return 1;
//			      }
//			      wikiParserBufferFree(buffer);
//			      buffer = NULL;
//			    } else {
//			      fprintf(stderr, "Error: could not allocate buffer: %lld\n", (long long)buffer->size);
//			      return 1;
//			    }
//			    wikiParserFree(parser);
//			    parser = NULL;
//			  } else {
//			    fprintf(stderr, "Error: could not create parser\n");
//			    return 1;
//			  }
//			  return 0;
//			}
//			}}}
//			
//			**Tokens**
//			
//			The following tokens are defined:
//			|= Token Types                               |= Field            |
//			| ##WIKI_PARSER_TOKEN_TYPE_NONE [1]##        |                   |
//			| ##WIKI_PARSER_TOKEN_TYPE_BOLD##            | ##state##         |
//			| ##WIKI_PARSER_TOKEN_TYPE_CODE##            | ##state##         |
//			| ##WIKI_PARSER_TOKEN_TYPE_DEFINITIONDESC##  |                   |
//			| ##WIKI_PARSER_TOKEN_TYPE_DEFINITIONLIST##  |                   |
//			| ##WIKI_PARSER_TOKEN_TYPE_DEFINITIONTERM##  |                   |
//			| ##WIKI_PARSER_TOKEN_TYPE_HEADING0 [2]##    |                   |
//			| ##WIKI_PARSER_TOKEN_TYPE_HEADING1##        | ##text##          |
//			| ##WIKI_PARSER_TOKEN_TYPE_HEADING2##        | ##text##          |
//			| ##WIKI_PARSER_TOKEN_TYPE_HEADING3##        | ##text##          |
//			| ##WIKI_PARSER_TOKEN_TYPE_HEADING4##        | ##text##          |
//			| ##WIKI_PARSER_TOKEN_TYPE_HEADING5##        | ##text##          |
//			| ##WIKI_PARSER_TOKEN_TYPE_HEADING6##        | ##text##          |
//			| ##WIKI_PARSER_TOKEN_TYPE_HORIZONTALRULE##  |                   |
//			| ##WIKI_PARSER_TOKEN_TYPE_IMAGE [3]##       | ##source [text]## |
//			| ##WIKI_PARSER_TOKEN_TYPE_ITALIC##          | ##state##         |
//			| ##WIKI_PARSER_TOKEN_TYPE_KEYBOARD##        | ##state##         |
//			| ##WIKI_PARSER_TOKEN_TYPE_LINEBREAK##       |                   |
//			| ##WIKI_PARSER_TOKEN_TYPE_LINK [3]##        | ##target [text]## |
//			| ##WIKI_PARSER_TOKEN_TYPE_LISTITEM##        |                   |
//			| ##WIKI_PARSER_TOKEN_TYPE_ORDEREDLIST##     |                   |
//			| ##WIKI_PARSER_TOKEN_TYPE_PARAGRAPH##       |                   |
//			| ##WIKI_PARSER_TOKEN_TYPE_PREFORMATTED##    | ##text##          |
//			| ##WIKI_PARSER_TOKEN_TYPE_SAMPLECODE##      | ##state##         |
//			| ##WIKI_PARSER_TOKEN_TYPE_SUBSCRIPT##       | ##state##         |
//			| ##WIKI_PARSER_TOKEN_TYPE_SUPERSCRIPT##     | ##state##         |
//			| ##WIKI_PARSER_TOKEN_TYPE_TABLE##           |                   |
//			| ##WIKI_PARSER_TOKEN_TYPE_TABLEDATA##       |                   |
//			| ##WIKI_PARSER_TOKEN_TYPE_TABLEHEADER##     |                   |
//			| ##WIKI_PARSER_TOKEN_TYPE_TABLEROW##        |                   |
//			| ##WIKI_PARSER_TOKEN_TYPE_TEXT [4]##        | ##text##          |
//			| ##WIKI_PARSER_TOKEN_TYPE_UNDERLINE##       | ##state##         |
//			| ##WIKI_PARSER_TOKEN_TYPE_UNORDEREDLIST##   |                   |
//			| ##WIKI_PARSER_TOKEN_TYPE_VARIABLE##        | ##state##         |
//			| ##WIKI_PARSER_TOKEN_TYPE_WIKINOWIKI [5]##  | ##state text##    |
//			| ##WIKI_PARSER_TOKEN_TYPE_WIKIPLACEHOLDER## | ##text##          |
//			| ##WIKI_PARSER_TOKEN_TYPE_WIKIPLUGIN##      | ##text##          |
//			**Special Notes:**
//			# Sent at the end of the token stream.
//			# For calculating header offsets, not used directly.
//			# The ##text## value is ##NULL## when image or link does not include pipe.
//			# When no text writer is configured (see ##[[#|wikiParserConfigureWriters]]##).
//			# The ##monospace## configuration option is passed in the ##state## field for convenience.
//

#include "wikiparser.h"
#include "ragelstuff.h"

#if !defined(NDEBUG)
int g_wikiParserStringCounter = 0;
#endif

#define MARKER_pipe 0
#define MAX_MARKER 1
#define MAX_PSTACK 32

typedef struct WikiParserParserStruct {
	void *userData; /* First for wikiParserGetUserData macro. */
	WikiParserConfig config; /* Second for special access. */
	int blockMode;
	int blockModeParam;
	int currentLine;
	enum WIKI_PARSER_ERROR error;
	struct FiniteStateMachineStruct {
		int act;
		int cs;
		const char *ts;
		const char *te;
		int stack[MAX_PSTACK];
		int top;
	} fsm;
	bool list[5];
	const char *marker[MAX_MARKER];
	enum WIKI_PARSER_TOKEN_TYPE stack[MAX_PSTACK];
	int top;
} WikiParserParser, *WikiParserParserPtr;

#define parserBlockMode (((WikiParserParserPtr)parser)->blockMode)
#define parserBlockModeParam (((WikiParserParserPtr)parser)->blockModeParam)
#define parserConfig (((WikiParserParserPtr)parser)->config)
#define parserCurrentLine (((WikiParserParserPtr)parser)->currentLine)
#define parserError (((WikiParserParserPtr)parser)->error)
#define parserFSM (((WikiParserParserPtr)parser)->fsm)
#define parserList (((WikiParserParserPtr)parser)->list)
#define parserMark(mark) (((WikiParserParserPtr)parser)->marker[MARKER_ ## mark])
#define parserMarker (((WikiParserParserPtr)parser)->marker)
#define parserStack (((WikiParserParserPtr)parser)->stack)
#define parserTop (((WikiParserParserPtr)parser)->top)
#define parserUserData (((WikiParserParserPtr)parser)->userData)

#define BLOCKMODE_OUTER 0x00 /* Outer ready mode (emit paragraph tokens when moving to inner paragraph mode). */
#define BLOCKMODE_PMODE 0x01 /* Paragraph mode (do not emit paragraph tokens when moving to inner paragraph mode). */
#define BLOCKMODE_INNER 0x02 /* Inner paragraph mode (emit paragraph tokens when moving from outer ready mode). */
#define BLOCKMODE_DTERM 0x04 /* Definition term. */
#define BLOCKMODE_DDESC 0x08 /* Definition description. */
#define BLOCKMODE_DMASK 0x0C /* Definition term description mask . */
#define BLOCKMODE_LIST1 0x10 /* List level 1. */
#define BLOCKMODE_LIST2 0x20 /* List level 2. */
#define BLOCKMODE_LIST3 0x30 /* List level 3. */
#define BLOCKMODE_LIST4 0x40 /* List level 4. */
#define BLOCKMODE_LIST5 0x50 /* List level 5. */
#define BLOCKMODE_LMASK 0x70 /* List level mask. */
#define BLOCKMODE_SHIFT 4 /* bits to shift for level. */
#define BLOCKMODE_TABLE 0x80 /* Table mode. */
#define BLOCKMODE_CLOSE 0x100 /* Special close flag. */

// private function prototypes

void WikiParserBufferTrim(WikiParserBuffer *text, char character);
bool wikiParserCommitBlock(WikiParser parser);
bool wikiParserCommitFinal(WikiParser parser);
bool wikiParserText(WikiParser parser, WikiParserBuffer *text);
bool wikiParserTextParagraph(WikiParser parser);
bool wikiParserToken(WikiParser parser, WikiParserToken *token);
bool wikiParserTokenClose(WikiParser parser, int tokenType);
bool wikiParserTokenCloseToggles(WikiParser parser);
bool wikiParserTokenOpen(WikiParser parser, int tokenType);
bool wikiParserTokenToggle(WikiParser parser, int tokenType);
bool wikiParserTokenToggle2(WikiParser parser, int topTokenType, int tailTokenType);

// FSM specification

%%{
	machine WikiParser;
	access parserFSM.;

	action additions { parserConfig.additions }

	action clear_pipe { parserMark(pipe) = NULL; }
	action set_pipe { parserMark(pipe) = fpc; }

	newline = '\n' @{ parserCurrentLine += 1; };
	any_count_line = ( any | newline );

	heading_ = ( '='{1,6} [^\n]+ );
	heading = ( heading_ when { parserBlockMode <= BLOCKMODE_PMODE } | newline ' '* heading_ );

	horizontal_rule_ = '-'{4,};
	horizontal_rule = ( horizontal_rule_ when { parserBlockMode <= BLOCKMODE_PMODE } | newline ' '* horizontal_rule_ );
	
	list_ = ((( '*' | '#' ) ' ' ) | (( '*' | '#' ){2,5} when { parserBlockMode & BLOCKMODE_LMASK }));
	list = ( list_ when { parserBlockMode <= BLOCKMODE_PMODE } | newline ' '* list_ );

	main := |*

		# Wiki creole block level markup.

		( heading newline ) => { // headings to level 6
			if (!wikiParserCommitBlock(parser)) fbreak;
			bool flag = (*parserFSM.ts == '\n');
			text.data = parserFSM.ts + (flag ? 1 : 0);
			text.size = parserFSM.te - 1 - text.data;
			temp = text;
			WikiParserBufferTrim(&temp, ' ');
			WikiParserBufferTrim(&temp, '=');
			int index = temp.data - text.data;
			WikiParserBufferTrim(&temp, ' ');
			text = temp;
			token = emptyWikiParserToken;
			token.type = WIKI_PARSER_TOKEN_TYPE_HEADING0 + index;
			token.text = &text;
			if (!wikiParserToken(parser, &token)) fbreak;
			parserCurrentLine -= 1;
			fhold;
		};

		( horizontal_rule newline ) => { // horizontal rule
			if (!wikiParserCommitBlock(parser)) fbreak;
			token = emptyWikiParserToken;
			token.type = WIKI_PARSER_TOKEN_TYPE_HORIZONTALRULE;
			if (!wikiParserToken(parser, &token)) fbreak;
			parserCurrentLine -= 1;
			fhold;
		};

		( list ) => { // lists to level 5
			bool flag = (*parserFSM.ts == '\n');
			temp.data = parserFSM.ts + (flag ? 1 : 0);
			temp.size = parserFSM.te - temp.data;
			WikiParserBufferTrim(&temp, ' ');
			int index = temp.size;
			parserList[index - 1] = (temp.data[temp.size - 1] == '#');
			int mode = (parserBlockMode & BLOCKMODE_LMASK) >> BLOCKMODE_SHIFT;
			if (mode > index) {
				if (!wikiParserTokenCloseToggles(parser)) fbreak;
				if (!wikiParserTokenClose(parser, WIKI_PARSER_TOKEN_TYPE_LISTITEM)) fbreak;
				while (mode > index) {
					if (!wikiParserTokenClose(parser, parserList[mode - 1] ? WIKI_PARSER_TOKEN_TYPE_ORDEREDLIST : 
							WIKI_PARSER_TOKEN_TYPE_UNORDEREDLIST)) fbreak;
					if (!wikiParserTokenClose(parser, WIKI_PARSER_TOKEN_TYPE_LISTITEM)) fbreak;
					mode--;
				}
			} else if (mode == index) {
				if (!wikiParserTokenCloseToggles(parser)) fbreak;
				if (!wikiParserTokenClose(parser, WIKI_PARSER_TOKEN_TYPE_LISTITEM)) fbreak;
			} else {
				if ((mode == 0) && !wikiParserCommitBlock(parser)) fbreak;
				if (!wikiParserTokenOpen(parser, parserList[index - 1] ? WIKI_PARSER_TOKEN_TYPE_ORDEREDLIST : 
						WIKI_PARSER_TOKEN_TYPE_UNORDEREDLIST)) fbreak;
			}
			if (!wikiParserTokenOpen(parser, WIKI_PARSER_TOKEN_TYPE_LISTITEM)) fbreak;
			parserBlockMode = index << BLOCKMODE_SHIFT;
		};

		( newline '|' '='? ) => { // table (row & initial cell)
			/* Newline is necessary here because without it the token is an exact copy of the next. */
			/* This means wiki documents cannot start with table (same for block pre-formatted). */
			bool header = (*(parserFSM.te - 1) == '=');
			if ((parserBlockMode & BLOCKMODE_TABLE) == 0) {
				if (!wikiParserCommitBlock(parser)) fbreak;
				if (!wikiParserTokenOpen(parser, WIKI_PARSER_TOKEN_TYPE_TABLE)) fbreak;
			} else {
				if (!wikiParserTokenClose(parser, WIKI_PARSER_TOKEN_TYPE_TABLEDATA)) fbreak;
				if (!wikiParserTokenClose(parser, WIKI_PARSER_TOKEN_TYPE_TABLEHEADER)) fbreak;
				if (!wikiParserTokenClose(parser, WIKI_PARSER_TOKEN_TYPE_TABLEROW)) fbreak;
			}
			if (!wikiParserTokenOpen(parser, WIKI_PARSER_TOKEN_TYPE_TABLEROW)) fbreak;
			if (!wikiParserTokenOpen(parser, header ? WIKI_PARSER_TOKEN_TYPE_TABLEHEADER : 
					WIKI_PARSER_TOKEN_TYPE_TABLEDATA)) fbreak;
			parserBlockMode = BLOCKMODE_TABLE;
		};

		( '|' '='? newline? ) when { parserBlockMode & BLOCKMODE_TABLE } => { // table (cell)
			if (!wikiParserTokenClose(parser, WIKI_PARSER_TOKEN_TYPE_TABLEDATA)) fbreak;
			if (!wikiParserTokenClose(parser, WIKI_PARSER_TOKEN_TYPE_TABLEHEADER)) fbreak;
			if (*(parserFSM.te - 1) == '\n') {
				parserBlockMode |= BLOCKMODE_CLOSE;
				parserCurrentLine -= 1;
				fhold;
			} else {
				bool header = (*(parserFSM.ts + 1) == '=');
				if (!wikiParserTokenOpen(parser, header ? WIKI_PARSER_TOKEN_TYPE_TABLEHEADER : 
						WIKI_PARSER_TOKEN_TYPE_TABLEDATA)) fbreak;
			}
		};

		( newline '{{{' newline any_count_line* :>> ( newline '}}}' )) => { // block pre-formatted
			/* Ignoring rule to include closing braces in preformatted blocks. */
			/* http://www.wikicreole.org/wiki/Creole1.0#section-Creole1.0-ClosingBracesInNowiki */
			if (!wikiParserCommitBlock(parser)) fbreak;
			bool flag = (*parserFSM.ts == '\n');
			text.data = parserFSM.ts + (flag ? 5 : 4);
			text.size = parserFSM.te - 4 - text.data;
			token = emptyWikiParserToken;
			token.type = WIKI_PARSER_TOKEN_TYPE_PREFORMATTED;
			token.text = &text;
			if (!wikiParserToken(parser, &token)) fbreak;
		};

		( newline{2,} ) => {
			if (!wikiParserCommitBlock(parser)) fbreak;
			parserCurrentLine -= 1;
			fhold;
		};

		# Wiki creole inline markup.

		( '~'? ( 'http://' | 'ftp://' )) => {
			if (!wikiParserTextParagraph(parser)) fbreak;
			bool flag = (*parserFSM.ts == '~');
			text.data = parserFSM.ts + (flag ? 1 : 0);
			text.size = parserFSM.te - parserFSM.ts;
			if (!wikiParserText(parser, &text)) fbreak;
		};

		( '\\\\' ) => { // line break
			if (!wikiParserTextParagraph(parser)) fbreak;
			token = emptyWikiParserToken;
			token.type = WIKI_PARSER_TOKEN_TYPE_LINEBREAK;
			if (!wikiParserToken(parser, &token)) fbreak;
		};

		( '{{{' any_count_line* :>> '}}}' '}'* ) => { // inline nowiki (optionally rendered in monospace)
			if (!wikiParserTextParagraph(parser)) fbreak;
			text.data = parserFSM.ts + 3;
			text.size = parserFSM.te - 3 - text.data;
			token = emptyWikiParserToken;
			token.type = WIKI_PARSER_TOKEN_TYPE_WIKINOWIKI;
			token.state = parserConfig.monospace;
			token.text = &text;
			if (!wikiParserToken(parser, &token)) fbreak;
		};

		( '<<<' any_count_line* :>> '>>>' '>'* ) => { // placeholder
			if (!wikiParserTextParagraph(parser)) fbreak;
			text.data = parserFSM.ts + 3;
			text.size = parserFSM.te - 3 - text.data;
			token = emptyWikiParserToken;
			token.type = WIKI_PARSER_TOKEN_TYPE_WIKIPLACEHOLDER;
			token.text = &text;
			if (!wikiParserToken(parser, &token)) fbreak;
		};

		( '<<' any_count_line* :>> '>>' '>'* ) => { // plugin
			if (!wikiParserTextParagraph(parser)) fbreak;
			text.data = parserFSM.ts + 2;
			text.size = parserFSM.te - 2 - text.data;
			token = emptyWikiParserToken;
			token.type = WIKI_PARSER_TOKEN_TYPE_WIKIPLUGIN;
			token.text = &text;
			if (!wikiParserToken(parser, &token)) fbreak;
		};

		( '[[' @clear_pipe any_count_line* ( '|' @set_pipe any_count_line* )? :>> ']]' ) => { // link
			if (!wikiParserTextParagraph(parser)) fbreak;
			text.data = parserFSM.ts + 2;
			text.size = parserFSM.te - 2 - text.data;
			token = emptyWikiParserToken;
			token.type = WIKI_PARSER_TOKEN_TYPE_LINK;
			token.target = &temp;
			if (parserMark(pipe)) {
				temp.data = text.data;
				temp.size = parserMark(pipe) - text.data;
				text.data = parserMark(pipe) + 1;
				text.size = text.size - temp.size - 1;
				if (text.size > 4
					&& text.data[0] == '{'
					&& text.data[1] == '{'
					&& text.data[text.size - 2] == '}'
					&& text.data[text.size - 1] == '}') {
					// image inside links hack
					text.data += 2;
					text.size -= 4;
					token.source = &text;
				}
				else {
					token.text = &text;
				}
			}
			else {
				temp.data = text.data;
				temp.size = text.size;
			}
			if (!wikiParserToken(parser, &token)) fbreak;
		};

		( '{{' @clear_pipe any_count_line* ( '|' @set_pipe any_count_line* )? :>> '}}' ) => { // image (inline)
			if (!wikiParserTextParagraph(parser)) fbreak;
			text.data = parserFSM.ts + 2;
			text.size = parserFSM.te - 2 - text.data;
			token = emptyWikiParserToken;
			token.type = WIKI_PARSER_TOKEN_TYPE_IMAGE;
			token.source = &temp;
			if (parserMark(pipe)) {
				temp.data = text.data;
				temp.size = parserMark(pipe) - text.data;
				text.data = parserMark(pipe) + 1;
				text.size = text.size - temp.size - 1;
				token.text = &text;
			}
			else {
				temp.data = text.data;
				temp.size = text.size;
			}
			if (!wikiParserToken(parser, &token)) fbreak;
		};

		( '**' ) => { // bold
			if (!wikiParserTextParagraph(parser)) fbreak;
			if (!wikiParserTokenToggle(parser, WIKI_PARSER_TOKEN_TYPE_BOLD)) fbreak;
		};

		( '//' ) => { // italic
			if (!wikiParserTextParagraph(parser)) fbreak;
			if (!wikiParserTokenToggle(parser, WIKI_PARSER_TOKEN_TYPE_ITALIC)) fbreak;
		};

		( '~' [^\n ] ) => { // escape character
			if (!wikiParserTextParagraph(parser)) fbreak;
			text.data = parserFSM.ts + 1;
			text.size = 1;
			if (!wikiParserText(parser, &text)) fbreak;
		};

		# Wiki creole block level markup additions.

		( newline ';' ) when additions => { // definition list (item)
			if ((parserBlockMode & BLOCKMODE_DTERM) == 0) {
				if (!wikiParserCommitBlock(parser)) fbreak;
				if (!wikiParserTokenOpen(parser, WIKI_PARSER_TOKEN_TYPE_DEFINITIONLIST)) fbreak;
			} else {
				if (!wikiParserTokenClose(parser, WIKI_PARSER_TOKEN_TYPE_DEFINITIONTERM)) fbreak;
				if (!wikiParserTokenClose(parser, WIKI_PARSER_TOKEN_TYPE_DEFINITIONDESC)) fbreak;
			}
			if (!wikiParserTokenOpen(parser, WIKI_PARSER_TOKEN_TYPE_DEFINITIONTERM)) fbreak;
			parserBlockMode = BLOCKMODE_DTERM; /* set/reset list */
		};

		( ':' ) when { parserConfig.additions && ((parserBlockMode & BLOCKMODE_DMASK) == BLOCKMODE_DTERM) } => { // definition list (definition)
			if (!wikiParserTokenClose(parser, WIKI_PARSER_TOKEN_TYPE_DEFINITIONTERM)) fbreak;
			if (!wikiParserTokenOpen(parser, WIKI_PARSER_TOKEN_TYPE_DEFINITIONDESC)) fbreak;
			parserBlockMode |= BLOCKMODE_DDESC; /* have used up the colon */
		};

		# Wiki creole inline markup additions.

		( '##' ) when additions => { // code
			if (!wikiParserTextParagraph(parser)) fbreak;
			if (!wikiParserTokenToggle(parser, WIKI_PARSER_TOKEN_TYPE_CODE)) fbreak;
		};

		( '#$' ) when additions => { // keyboard head, samplecode tail
			if (!wikiParserTextParagraph(parser)) fbreak;
			if (!wikiParserTokenToggle2(parser, 
					WIKI_PARSER_TOKEN_TYPE_KEYBOARD, WIKI_PARSER_TOKEN_TYPE_SAMPLECODE)) fbreak;
		};

		( '$#' ) when additions => { // samplecode head, keyboard tail
			if (!wikiParserTextParagraph(parser)) fbreak;
			if (!wikiParserTokenToggle2(parser, 
					WIKI_PARSER_TOKEN_TYPE_SAMPLECODE, WIKI_PARSER_TOKEN_TYPE_KEYBOARD)) fbreak;
		};

		( ',,' ) when additions => { // subscript
			if (!wikiParserTextParagraph(parser)) fbreak;
			if (!wikiParserTokenToggle(parser, WIKI_PARSER_TOKEN_TYPE_SUBSCRIPT)) fbreak;
		};

		( '^^' ) when additions => { // superscript
			if (!wikiParserTextParagraph(parser)) fbreak;
			if (!wikiParserTokenToggle(parser, WIKI_PARSER_TOKEN_TYPE_SUPERSCRIPT)) fbreak;
		};

		( '__' ) when additions => { // underline
			if (!wikiParserTextParagraph(parser)) fbreak;
			if (!wikiParserTokenToggle(parser, WIKI_PARSER_TOKEN_TYPE_UNDERLINE)) fbreak;
		};

		( '$$' ) when additions => { // variable
			if (!wikiParserTextParagraph(parser)) fbreak;
			if (!wikiParserTokenToggle(parser, WIKI_PARSER_TOKEN_TYPE_VARIABLE)) fbreak;
		};

		# Paragraph text.

		( ( ( alnum+ ) - ( 'http' | 'ftp' ) ) | any_count_line ) => {
			text.data = parserFSM.ts;
			text.size = parserFSM.te - parserFSM.ts;
			bool isNewParagraph = parserBlockMode <= BLOCKMODE_PMODE;
			if ((parserBlockMode & BLOCKMODE_CLOSE) && !wikiParserCommitBlock(parser)) fbreak;
			if (!wikiParserTextParagraph(parser)) fbreak;
			if (parserConfig.blogstyle && !isNewParagraph && *text.data == '\n') {
				token = emptyWikiParserToken;
				token.type = WIKI_PARSER_TOKEN_TYPE_LINEBREAK;
				if (!wikiParserToken(parser, &token)) fbreak;
				text.size -= 1;
			}
			if (text.size) {
				if (!wikiParserText(parser, &text)) fbreak;
			}
		};

	*|;
}%%

%% write data;

void wikiParserParserInit(WikiParser parser, int blockMode)
{
	parserBlockMode = blockMode & BLOCKMODE_PMODE;
	parserBlockModeParam = parserBlockMode;
	parserCurrentLine = 1;
	parserTop = 0;
	RAGEL_WRITE_INIT_PREP(MAX_MARKER);
	%% write init;
}

void wikiParserParserExec(WikiParser parser, ExecPrivateBlockData *data)
{
	WikiParserBuffer temp = emptyWikiParserBuffer;
	WikiParserBuffer text = emptyWikiParserBuffer;
	WikiParserToken token = emptyWikiParserToken;
	RAGEL_WRITE_EXEC_IN();
	%% write exec;
	RAGEL_WRITE_EXEC_OUT();
}

// private functions

void WikiParserBufferTrim(WikiParserBuffer *text, char character)
{
	const char *trim = text->data + text->size;
	while (text->data < trim && *text->data == character) text->data++;
	while (trim > text->data && *(trim - 1) == character) trim--;
	text->size = trim - text->data;
}

bool wikiParserCommitBlock(WikiParser parser)
{
	bool error = false;
	int index = parserTop;
	while (index) {
		int tokenType = parserStack[index - 1];
		WikiParserToken token = emptyWikiParserToken;
		token.type = tokenType;
		token.state = false;
		error = !wikiParserToken(parser, &token);
		if (error) break;
		index--;
	};
	parserBlockMode = parserBlockModeParam;
	parserTop = 0;
	return !error;
}

bool wikiParserCommitFinal(WikiParser parser)
{
	bool error = !wikiParserCommitBlock(parser);
	if (!error) {
		WikiParserToken token = emptyWikiParserToken;
		token.type = WIKI_PARSER_TOKEN_TYPE_NONE;
		error = !wikiParserToken(parser, &token);
	}
	return !error;
}

bool wikiParserText(WikiParser parser, WikiParserBuffer *text)
{
	bool error = false;
	if (parserConfig.writeText) {
		if (!parserConfig.writeText(parserUserData, text)) {
			parserError = WIKI_PARSER_ERROR_WRITER;
			error = true;
		}
	} else {
		WikiParserToken token = emptyWikiParserToken;
		token.type = WIKI_PARSER_TOKEN_TYPE_TEXT;
		token.text = text;
		error = !wikiParserToken(parser, &token);
	}
	return !error;
}

bool wikiParserTextParagraph(WikiParser parser)
{
	bool error = false;
	if (parserBlockMode <= BLOCKMODE_PMODE) {
		if (parserBlockMode == BLOCKMODE_OUTER) {
			error = !wikiParserTokenOpen(parser, WIKI_PARSER_TOKEN_TYPE_PARAGRAPH);
		}
		parserBlockMode = BLOCKMODE_INNER;
	}
	return !error;
}

bool wikiParserToken(WikiParser parser, WikiParserToken *token)
{
	bool error = false;
	if (parserConfig.writeToken) {
		if (!parserConfig.writeToken(parserUserData, token)) {
			parserError = WIKI_PARSER_ERROR_WRITER;
			error = true;
		}
	}
	return !error;
}

bool wikiParserTokenClose(WikiParser parser, int tokenType)
{
	bool error = false;
	int index = parserTop;
	while (index) {
		if (parserStack[index - 1] == tokenType) break;
		index--;
	};
	if (index > 0) {
		WikiParserToken token = emptyWikiParserToken;
		token.type = tokenType;
		token.state = false;
		error = !wikiParserToken(parser, &token);
		while (index < parserTop) {
			parserStack[index - 1] = parserStack[index];
			index++;
		}
		parserTop--;
	}
	return !error;
}

bool wikiParserTokenCloseToggles(WikiParser parser)
{
	bool error = false;
	int index = parserTop;
	while (index && !error) {
		int tokenType = parserStack[index - 1];
		switch (tokenType) {
			case WIKI_PARSER_TOKEN_TYPE_BOLD:
			case WIKI_PARSER_TOKEN_TYPE_CODE:
			case WIKI_PARSER_TOKEN_TYPE_ITALIC:
			case WIKI_PARSER_TOKEN_TYPE_KEYBOARD:
			case WIKI_PARSER_TOKEN_TYPE_SAMPLECODE:
			case WIKI_PARSER_TOKEN_TYPE_SUBSCRIPT:
			case WIKI_PARSER_TOKEN_TYPE_SUPERSCRIPT:
			case WIKI_PARSER_TOKEN_TYPE_UNDERLINE:
			case WIKI_PARSER_TOKEN_TYPE_VARIABLE:
				error = !wikiParserTokenClose(parser, tokenType);
				break;
		}
		index--;
	};
	return !error;
}

bool wikiParserTokenOpen(WikiParser parser, int tokenType)
{
	bool error = false;
	WikiParserToken token = emptyWikiParserToken;
	token.type = tokenType;
	token.state = true;
	error = !wikiParserToken(parser, &token);
	parserStack[parserTop++] = tokenType;
	return !error;
}

bool wikiParserTokenToggle(WikiParser parser, int tokenType)
{
	return wikiParserTokenToggle2(parser, tokenType, tokenType);
}

bool wikiParserTokenToggle2(WikiParser parser, int topTokenType, int tailTokenType)
{
	bool error = false;
	int index = parserTop;
	while (index) {
		if (parserStack[index - 1] == tailTokenType) break;
		index--;
	};
	if (index == 0) {
		int tokenType = parserStack[parserTop++] = topTokenType;
		WikiParserToken token = emptyWikiParserToken;
		token.type = tokenType;
		token.state = true;
		error = !wikiParserToken(parser, &token);
	} else {
		WikiParserToken token = emptyWikiParserToken;
		token.type = tailTokenType;
		token.state = false;
		error = !wikiParserToken(parser, &token);
		while (index < parserTop) {
			parserStack[index - 1] = parserStack[index];
			index++;
		}
		parserTop--;
	}
	return !error;
}

// public functions

//======================================================================
//
// Spec:	Wiki Parser API
//
//----------------------------------------------------------------------
//
// Func:	createWikiParser => WikiParser WIKIPARSERAPI createWikiParser(WikiParserConfig *config)
//			Create a new ##parser## object. The parser must be freed with ##[[#|wikiParserFree]]## when no longer needed.
//
// Param:	config => WikiParserConfig *
//			(optional) The config object. If the value is NULL the standard ##emptyWikiParserConfig## config is used. 
//			With ##emptyWikiParserConfig## all options are set to ##false## and the writers set to ##NULL##.
//
// Return:	parser => WikiParser
//			The new parser object. Note: The value will be ##NULL## if memory could not be allocated.
//

WikiParser WIKIPARSERAPI createWikiParser(WikiParserConfig *config)
{
	WikiParser parser = malloc(sizeof(WikiParserParser));
	if (parser) {
		parserUserData = NULL;
		parserConfig = config ? *config : emptyWikiParserConfig;
		parserCurrentLine = 0;
		parserError = 0;
	}
	return parser;
}

//----------------------------------------------------------------------
//
// Func:	createWikiParserBuffer => WikiParserBuffer WIKIPARSERAPI *createWikiParserBuffer(size_t size)
//			Create a new ##buffer## object. The buffer must be freed with ##[[#|wikiParserBufferFree]]## when no longer needed.
//
// Param:	size => size_t
//			The buffer size.
//
// Return:	buffer => WikiParserBuffer *
//			The new buffer object. Note: The value will be ##NULL## if memory could not be allocated.
//

WikiParserBuffer WIKIPARSERAPI *createWikiParserBuffer(size_t size)
{
	if (size <= 0) size = WIKI_PARSER_BUFFER_SIZE;
	WikiParserBuffer *buffer = malloc(sizeof(WikiParserBufferPtr) + size + 1);
	if (buffer) {
		buffer->data = (const char *)(buffer + sizeof(WikiParserBufferPtr));
		((char *)buffer->data)[size] = '\0';
		buffer->size = size;
	}
	return buffer;
}

//----------------------------------------------------------------------
//
// Func:	createWikiParserString => char WIKIPARSERAPI *createWikiParserString(const char *data, size_t size)
//			Create a new ##string## object with text. The string must be freed with ##[[#|wikiParserStringFree]]## when no longer needed.
//
// Param:	data => const char *
//			The text buffer data.
//
// Param:	size => size_t
//			The text buffer size.
//
// Return:	string => char *
//			The new string object. Note: The value will be ##NULL## if memory could not be allocated.
//

char WIKIPARSERAPI *createWikiParserString(const char *data, size_t size)
{
	assert(data);
	assert(size >= 0);
	char *string = malloc(size + 1);
	if (string) {
		#if !defined(NDEBUG)
		g_wikiParserStringCounter++;
		#endif
		strncpy(string, data, size);
		string[size] = '\0';
	}
	return string;
}

//----------------------------------------------------------------------
//
// Func:	wikiParserBufferFree => void WIKIPARSERAPI wikiParserBufferFree(WikiParserBuffer *buffer)
//			Free the memory allocated to ##buffer##. The buffer must be a valid buffer created with an earlier 
//			call to [[#|createWikiParserBuffer]]. The buffer value must not be used after it is freed. It 
//			is good practice to set the buffer value to ##NULL## after calling this function.
//
// Param:	buffer => WikiParserBuffer *
//			The buffer to be freed.
//
// Return:	none => void
//

void WIKIPARSERAPI wikiParserBufferFree(WikiParserBuffer *buffer)
{
	assert(buffer);
	free(buffer);
}

//----------------------------------------------------------------------
//
// Func:	wikiParserConfigureOptions => void WIKIPARSERAPI wikiParserConfigureOptions(WikiParser parser, bool additions, bool blogstyle, bool monospace)
//			Configure the options for the parser. These options are applied to a copy of the original config object (if any)
//			which was passed in the call to [[#|createWikiParser]]. The original config object remains unchanged.
//
// Param:	parser => WikiParser
//			The parser object.
//
// Param:	additions => bool
//			##true## to enable additional features specified in the [[http://www.wikicreole.org/wiki/CreoleAdditions|Creole 1.0 Additions]], including:
//			* Code (Monospace)
//			* Definition lists
//			* Plug-in/Extension
//			* Subscript
//			* Superscript
//			* Underline
//			
//			and experimental features, including:
//			* (##{{{#$...$#}}}##) Keyboard
//			* (##{{{$#...#$}}}##) Samplecode
//			* (##{{{$$...$$}}}##) Variable
//
// Param:	blogstyle => bool
//			##true## to enable blog-style line breaks instead of wiki-style line breaks (the default). See 
//			[[http://www.wikicreole.org/wiki/ParagraphsAndLineBreaksReasoning|Creole 1.0 Paragraphs And Line Breaks Reasoning]] 
//			for details.
//
// Param:	monospace => bool
//			##true## to enable monospace in the ##WIKI_PARSER_TOKEN_TYPE_WIKINOWIKI## token. This option is passed to the token writer, the parser does not do anything special.
//			See [[http://www.wikicreole.org/wiki/Creole1.0#section-Creole1.0-NowikiPreformatted|Creole 1.0 Nowiki Preformatted]] for more information.
//
// Return:	none => void
//

void WIKIPARSERAPI wikiParserConfigureOptions(WikiParser parser, bool additions, bool blogstyle, bool monospace)
{
	assert(parser);
	parserConfig.additions = additions;
	parserConfig.blogstyle = blogstyle;
	parserConfig.monospace = monospace;
}

//----------------------------------------------------------------------
//
// Func:	wikiParserConfigureWriters => void WIKIPARSERAPI wikiParserConfigureWriters(WikiParser parser, WriteTextFunc writeText, WriteTokenFunc writeToken)
//			Configure the text and token writer callbacks for the parser. These writer callbacks are applied to a copy of the original config 
//			object (if any) which was passed in the call to [[#|createWikiParser]]. The original config object remains unchanged.
//			
//			The ##WriteTextFunc## text and ##WriteTokenFunc## token writer callbacks are declared as follows:
//			
//			{{{
//			typedef bool (*WriteTextFunc)(void *userData, WikiParserBuffer *text);
//			
//			bool wikiTextWriter(void *userData, WikiParserBuffer *text)
//			{
//			    bool error = false;
//			    // process the text...
//			    return !error;
//			}
//			
//			typedef bool (*WriteTokenFunc)(void *userData, WikiParserToken *token);
//			
//			bool wikiTokenWriter(void *userData, WikiParserToken *token)
//			{
//			    bool error = false;
//			    // process the token...
//			    return !error;
//			}
//			}}}
//			
//			Return ##true## on success and ##false## on failure. Record any specific error details in ##userData## if they are needed.
//
// Param:	parser => WikiParser
//			The parser object.
//
// Param:	writeText => WriteTextFunc
//			(optional) The text writer callback. If the value is ##NULL## text is sent to the 
//			token writer in the ##WIKI_PARSER_TOKEN_TYPE_TEXT## token.
//
// Param:	writeToken => WriteTokenFunc
//			The token writer callback.
//
// Return:	none => void
//

void WIKIPARSERAPI wikiParserConfigureWriters(WikiParser parser, WriteTextFunc writeText, WriteTokenFunc writeToken)
{
	assert(parser);
	parserConfig.writeText = writeText;
	parserConfig.writeToken = writeToken;
}

//----------------------------------------------------------------------
//
// Func:	wikiParserFree => void WIKIPARSERAPI wikiParserFree(WikiParser parser)
//			Free the memory allocated to ##parser##. The parser must be a valid parser created with an earlier 
//			call to [[#|createWikiParser]]. The parser value must not be used after it is freed. It 
//			is good practice to set the parser value to ##NULL## after calling this function.
//
// Param:	parser => WikiParser
//			The parser to be freed.
//
// Return:	none => void
//

void WIKIPARSERAPI wikiParserFree(WikiParser parser)
{
	assert(parser);
	free(parser);
}

//----------------------------------------------------------------------
//
// Func:	wikiParserGetCurrentLine => int WIKIPARSERAPI wikiParserGetCurrentLine(WikiParser parser)
//			Return the current line of the parser. Line numbers start from ##1## and continue to the end of the document. 
//			Before the parser has started the value will be ##0##, on completion the value will be the total number of 
//			lines in the document. When an error occurs the value will be the line the error occurred on.
//
// Param:	parser => WikiParser
//			The parser object.
//
// Return:	value => int
//			The current line.
//

int WIKIPARSERAPI wikiParserGetCurrentLine(WikiParser parser)
{
	assert(parser);
	return parserCurrentLine;
}

//----------------------------------------------------------------------
//
// Func:	wikiParserGetErrorCode => enum WIKI_PARSER_ERROR WIKIPARSERAPI wikiParserGetErrorCode(WikiParser parser)
//			Return the error code of the parser. The error code is set when an error occurs during parsing.
//			Errors which occur during reading or writing are caught in the parser and returned as 
//			##WIKI_PARSER_ERROR_READER## and ##WIKI_PARSER_ERROR_WRITER## respectively. Readers and writers
//			should record any specific error details in ##userData## if they are needed. The ##WIKI_PARSER_ERROR_PARSER##
//			error indicates a syntax error, ##WIKI_PARSER_ERROR_MEMORY## indicates an out of memory error, 
//			##WIKI_PARSER_ERROR_BUFFER## indicates a token in the stream was too big for the user supplied buffer.
//			See also ##[[#|wikiParserGetErrorString]].
//			
//			|= Errors                       |= Description                       |
//			| ##JSON_PARSER_ERROR_UNKNOWN## | An unknown error occurred.         |
//			| ##JSON_PARSER_ERROR_NONE##    | No error.                          |
//			| ##JSON_PARSER_ERROR_BUFFER##  | Token too big for buffer.          |
//			| ##JSON_PARSER_ERROR_MEMORY##  | An out of memory error occurred.   |
//			| ##JSON_PARSER_ERROR_PARSER##  | Input could not be parsed.         |
//			| ##JSON_PARSER_ERROR_PSTACK##  | Parser stack overflow.             |
//			| ##JSON_PARSER_ERROR_READER##  | An error occurred with the reader. |
//			| ##JSON_PARSER_ERROR_WRITER##  | An error occurred with the writer. |
//			
//			The ##WIKI_PARSER_ERROR_NONE## error is equal to ##0##, ##WIKI_PARSER_ERROR_UNKNOWN## is less than ##0##, 
//			all other errors are greater than ##0##.
//
// Param:	parser => WikiParser
//			The parser object.
//
// Return:	value => enum WIKI_PARSER_ERROR
//			The error code.
//

enum WIKI_PARSER_ERROR WIKIPARSERAPI wikiParserGetErrorCode(WikiParser parser)
{
	assert(parser);
	return parserError;
}

//----------------------------------------------------------------------
//
// Func:	wikiParserGetErrorString => const char WIKIPARSERAPI *wikiParserGetErrorString(WikiParser parser)
//			Return the error string associated with the error code of the parser. See ##[[#|wikiParserGetErrorCode]] for details.
//
// Param:	parser => WikiParser
//			The parser object.
//
// Return:	value => const char *
//			The error string.

const char WIKIPARSERAPI *wikiParserGetErrorString(WikiParser parser)
{
	assert(parser);
	switch (parserError) {
		case WIKI_PARSER_ERROR_NONE:
			return "WIKI_PARSER_ERROR_NONE";
		case WIKI_PARSER_ERROR_UNKNOWN:
			return "WIKI_PARSER_ERROR_UNKNOWN";
		case WIKI_PARSER_ERROR_MEMORY:
			return "WIKI_PARSER_ERROR_MEMORY";
		case WIKI_PARSER_ERROR_PARSER:
			return "WIKI_PARSER_ERROR_PARSER";
		case WIKI_PARSER_ERROR_BUFFER:
			return "WIKI_PARSER_ERROR_BUFFER";
		case WIKI_PARSER_ERROR_READER:
			return "WIKI_PARSER_ERROR_READER";
		case WIKI_PARSER_ERROR_WRITER:
			return "WIKI_PARSER_ERROR_WRITER";
		default:
			return NULL;
	}
}

//----------------------------------------------------------------------
//
// Func:	wikiParserGetUserData => void WIKIPARSERAPI *wikiParserGetUserData(WikiParser parser)
//			Return user data associated with the parser in an earlier call to ##[[#|wikiParserSetUserData]]##. 
//			The ##void *userData## should be recast to use. Callback functions are provided the same ##void *userData##. 
//			Macros can make using the user data easier, for example:
//			
//			{{{
//			#define userDataRowCount (((Wiki2HTMLUserDataPtr)userData)->rowCount)
//			}}}
//
// Param:	parser => WikiParser
//			The parser object.
//
// Return:	value => void *
//			The user data.
//

/* #define wikiParserGetUserData(parser) (*(void **)(parser)) */

//----------------------------------------------------------------------
//
// Func:	wikiParserParseStream => bool WIKIPARSERAPI wikiParserParseStream(WikiParser parser, WikiParserBuffer *buffer, ReaderFunc reader, int blockMode)
//			Parse the reader input. Parsed text and tokens are streamed to the writers.
//			
//			The ##ReaderFunc## reader callback is declared as follows:
//			
//			{{{
//			typedef bool (*ReaderFunc)(void *userData, WikiParserBuffer *buffer, size_t *size);
//			
//			bool wikiParserStandardInputReader(void *userData, WikiParserBuffer *buffer, size_t *size) {
//			    *size = fread((char *)buffer->data, 1, buffer->size, stdin);
//			    return ferror(stdin) == 0;
//			}
//			}}}
//			
//			Return ##true## on success and ##false## on failure. Record any specific error details in ##userData## if they are needed.
//
// Param:	parser => WikiParser
//			The parser object.
//
// Param:	buffer => WikiParserBufferPtr
//			The buffer for the parser. Buffer management functions are performed automatically.
//
// Param:	reader => ReaderFunc
//			(optional) The parser calls this functions whenever it needs to fill the buffer. If the value 
//			is NULL the default ##[[#|wikiParserStandardInputReader]]## callback function is used.
//
// Param:	blockMode => int
//			Set the parser block mode: ##0## for normal, ##1## for paragraph mode (does not emit paragraph tokens 
//			when moving to inner paragraph mode). Paragraph mode is useful in cases where text is 
//			parsed and included in an outer paragraph or other block elements like list etc.
//
// Return:	success => bool
//			Returns ##true## on success and ##false## on failure. Call the ##[[#|wikiParserGetErrorCode]]## 
//			and ##[[#|wikiParserGetErrorString]]## functions for information about the failure.
//			Possible errors include: ##WIKI_PARSER_ERROR_BUFFER##, ##WIKI_PARSER_ERROR_PARSER##, 
//			##WIKI_PARSER_ERROR_READER##, and ##WIKI_PARSER_ERROR_WRITER##.
//

bool WIKIPARSERAPI wikiParserParseStream(WikiParser parser, WikiParserBuffer *buffer, ReaderFunc reader, int blockMode)
{
	assert(parser);
	assert(buffer);
	bool error = false;
	wikiParserParserInit(parser, blockMode);
	if (!reader) reader = wikiParserStandardInputReader;
	RAGEL_PARSE_STREAM(wikiParserParserExec, WikiParser, WIKI_PARSER_ERROR, MAX_MARKER);
	/* The following should be done using EOF action embedding operators! */
	if (!error) error = !wikiParserCommitFinal(parser);
	return !error;
}

//----------------------------------------------------------------------
//
// Func:	wikiParserParseString => bool WIKIPARSERAPI wikiParserParseString(WikiParser parser, char *string, int blockMode)
//			Parse the string. Parsed text and tokens are streamed to the writers.
//
// Param:	parser => WikiParser
//			The parser object.
//
// Param:	string => char *
//			The string to parse.
//
// Param:	blockMode => int
//			Set the parser block mode: ##0## for normal, ##1## for paragraph mode (does not emit paragraph tokens 
//			when moving to inner paragraph mode). Paragraph mode is useful in cases where text is 
//			parsed and included in an outer paragraph or other block elements like list etc.
//
// Return:	success => bool
//			Returns ##true## on success and ##false## on failure. Call the ##[[#|wikiParserGetErrorCode]]## and 
//			##[[#|wikiParserGetErrorString]]## functions for information about the failure.
//			Possible errors include: ##WIKI_PARSER_ERROR_PARSER##, and ##WIKI_PARSER_ERROR_WRITER##.
//

bool WIKIPARSERAPI wikiParserParseString(WikiParser parser, char *string, int blockMode)
{
	assert(parser);
	assert(string);
	bool error = false;
	wikiParserParserInit(parser, blockMode);
	RAGEL_PARSE_STRING(wikiParserParserExec, WikiParser, WIKI_PARSER_ERROR, MAX_MARKER);
	/* The following should be done using EOF action embedding operators! */
	if (!error) error = !wikiParserCommitFinal(parser);
	return !error;
}

//----------------------------------------------------------------------
//
// Func:	wikiParserSetUserData => void WIKIPARSERAPI *wikiParserSetUserData(WikiParser parser, void *userData)
//			Associate user data with the parser for callback functions. See also ##[[#|wikiParserGetUserData]]##.
//
// Param:	parser => WikiParser
//			The parser object.
//
// Param:	userData => void *
//			The user data.
//
// Return:	none => void
//

void WIKIPARSERAPI *wikiParserSetUserData(WikiParser parser, void *userData)
{
	assert(parser);
	void *previous = parserUserData;
	parserUserData = userData;
	return previous;
}

//----------------------------------------------------------------------
//
// Func:	wikiParserStandardInputReader => bool wikiParserStandardInputReader(void *userData, WikiParserBuffer *buffer, size_t *size)
//			The default reader callback for filling the buffer with ##stdin##. See also ##[[#|wikiParserParseStream]]##.
//
// Param:	userData => void *
//			The user data associated with the parser.
//
// Param:	buffer => WikiParserBuffer *
//			The buffer to read into.
//
// Param:	size => size_t *
//			Pointer for returning the amount of bytes read into the buffer.
//
// Return:	success => bool
//			Returns ##true## on success and ##false## on failure. No specific error details are recorded for ##WIKI_PARSER_ERROR_READER##.
//

bool wikiParserStandardInputReader(void *userData, WikiParserBuffer *buffer, size_t *size) {
	*size = fread((char *)buffer->data, 1, buffer->size, stdin);
	return ferror(stdin) == 0;
}

//----------------------------------------------------------------------
//
// Func:	wikiParserStringAppend => char WIKIPARSERAPI *wikiParserStringAppend(char *string, const char *data, size_t size)
//			Append text to ##string##. The string must be a valid string created with an earlier call to [[#|createWikiParserString]].
//			The string must be freed with ##[[#|wikiParserStringFree]]## when no longer needed.
//
// Param:	string => char *
//			(optional) The string object. If the value is NULL a new string will be created.
//
// Param:	data => const char *
//			The text buffer data.
//
// Param:	size => size_t
//			The text buffer size.
//
// Return:	string => char *
//			The (possibly) new string object. Note: The value will be ##NULL## if memory could not be allocated.
//

char WIKIPARSERAPI *wikiParserStringAppend(char *string, const char *data, size_t size)
{
	assert(data);
	assert(size >= 0);
	char *pointer = string;
	size_t current = pointer ? strlen(pointer) : 0;
	string = realloc(pointer, current + size + 1);
	if (string) {
		#if !defined(NDEBUG)
		if (!pointer) g_wikiParserStringCounter++;
		#endif
		strncpy(string + current, data, size);
		string[current + size] = '\0';
	}
	return string;
}

//----------------------------------------------------------------------
//
// Func:	wikiParserStringFree => void WIKIPARSERAPI wikiParserStringFree(char *string)
//			Free the memory allocated to ##string##. The string must be a valid string created with an earlier 
//			call to [[#|createWikiParserString]]. The string value must not be used after it is freed. It 
//			is good practice to set the string value to ##NULL## after calling this function.
//
// Param:	string => char *
//			The string to be freed.
//
// Return:	none => void
//

void WIKIPARSERAPI wikiParserStringFree(char *string)
{
	assert(string);
	#if !defined(NDEBUG)
	g_wikiParserStringCounter--;
	#endif
	free(string);
}

//======================================================================
//
// Topic:	Release Notes
//			<<<include:release-notes>>>
//

// readme -t ../readme/spec.tmpl -mwx wikiparser.rl wikiparser.h > wikiparser.html
//
// readme -t kinoma/webapps/tools/readme/plain.tmpl kinoma/webapps/tools/wiki/wikiparser.c kinoma/webapps/tools/wiki/wikiparser.h > kinoma/webapps/tools/wiki/wikiparser.txt
// kinoma/webapps/javascript/kss/scripts/docs.sh -d kinoma/webapps/tools/wiki
// rm kinoma/webapps/tools/wiki/wikiparser.txt

/* END OF FILE */
