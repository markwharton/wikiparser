/*

C wiki parser library and sample application.

Copyright (c) 2010, Mark Wharton
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

- Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

- Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

*/
#include <wikiparser.h>
#include <ctype.h>
#include <unistd.h>

#define MAX_HEADINGS WIKI_PARSER_TOKEN_TYPE_HEADING6 - WIKI_PARSER_TOKEN_TYPE_HEADING0

typedef struct Wiki2HTMLUserDataStruct {
	int headings[MAX_HEADINGS];
	bool indexed;
	int lastIndex;
	char* outlink;
	int rowCount;
} Wiki2HTMLUserData, *Wiki2HTMLUserDataPtr;

#define userDataHeadings (((Wiki2HTMLUserDataPtr)userData)->headings)
#define userDataIndexed (((Wiki2HTMLUserDataPtr)userData)->indexed)
#define userDataLastIndex (((Wiki2HTMLUserDataPtr)userData)->lastIndex)
#define userDataOutlink (((Wiki2HTMLUserDataPtr)userData)->outlink)
#define userDataRowCount (((Wiki2HTMLUserDataPtr)userData)->rowCount)

bool echoHeadingID(void *userData, WikiParserBuffer *text)
{
	bool error = false;
	char *id = createWikiParserString(text->data, text->size);
	if (id) {
		int i = 0;
		char *p = id;
		for (; i < text->size; i++) {
			char c = text->data[i];
			if (isalnum(c)) *p++ = tolower(c);
			else if (p > id && *(p - 1) != '-') *p++ = '-';
		}
		*p = '\0';
		error = fprintf(stdout, "%s", id) <= 0;
		wikiParserStringFree(id);
		id = NULL;
	}
	else error = true; // out of memory
	return !error;
}

bool echoHeadingIndex(void *userData, int index)
{
	bool error = false;
	int i = 1; /* skip title */
	for (; i < index && !error; i++) {
		error = fprintf(stdout, "%d.", userDataHeadings[i]) <= 0;
	}
	for (; i < MAX_HEADINGS; i++) {
		userDataHeadings[i] = 0;
	}
	return !error;
}

%%{
	machine EscapeTextWriter;
	write data;
}%%

#pragma unused (EscapeTextWriter_en_main,EscapeTextWriter_error)

bool escapeTextWriter(void *userData, WikiParserBuffer *text)
{
	assert(text);
	bool error = false;
	const char *p = text->data;
	const char *pe = text->data + text->size;
	const char *eof = pe;
	int act;
	int cs;
	const char *ts;
	const char *te;

	%%{
		main := |*
			'&' { if ((error = fprintf(stdout, "&amp;" ) <= 0)) fbreak; };
			'<' { if ((error = fprintf(stdout, "&lt;"  ) <= 0)) fbreak; };
			'>' { if ((error = fprintf(stdout, "&gt;"  ) <= 0)) fbreak; };
			'"' { if ((error = fprintf(stdout, "&quot;") <= 0)) fbreak; };
			[^&<>""]+ { if ((error = fwrite(ts, te - ts, 1, stdout) <= 0)) fbreak; };
		*|;

		# Initialize and execute.
		write init;
		write exec;
	}%%

	if (!error) error = cs < EscapeTextWriter_first_final;
	return !error;
}

bool wikiReader(void *userData, WikiParserBuffer *buffer, size_t *size) {
	*size = fread((char *)buffer->data, 1, buffer->size, stdin);
	return ferror(stdin) == 0;
}

bool wikiTitleWriter(void *userData, WikiParserToken *token)
{
	assert(token);
	bool error = false;
	switch (token->type) {
		case WIKI_PARSER_TOKEN_TYPE_HEADING1:
		{
			int index = token->type - WIKI_PARSER_TOKEN_TYPE_HEADING0;
			int i = index - 1;
			if (userDataHeadings[i] == 0) {
				if (!error) error = !escapeTextWriter(userData, token->text);
				userDataHeadings[i] = 1;
			}
			break;
		}
		default:
			break;
	}
	return !error;
}

bool wikiTOCWriter(void *userData, WikiParserToken *token)
{
	assert(token);
	bool error = false;
	switch (token->type) {
		case WIKI_PARSER_TOKEN_TYPE_HEADING0: /* Not used directly; for calculations. */
		case WIKI_PARSER_TOKEN_TYPE_HEADING1: /* title */
		case WIKI_PARSER_TOKEN_TYPE_HEADING2: /* 1. */
		case WIKI_PARSER_TOKEN_TYPE_HEADING3: /* 1.1. */
		case WIKI_PARSER_TOKEN_TYPE_HEADING4: /* 1.1.1. */
		case WIKI_PARSER_TOKEN_TYPE_HEADING5: /* 1.1.1.1. */
		case WIKI_PARSER_TOKEN_TYPE_HEADING6: /* 1.1.1.1.1. */
		{
			int index = token->type - WIKI_PARSER_TOKEN_TYPE_HEADING0;
			int i = index - 1;
			userDataHeadings[i]++;
			if (i) {
				i = index - userDataLastIndex;
				if (i < 0) {
					i = -i;
					while (i-- && !error) error = fprintf(stdout, "</ol>") <= 0;
				}
				else if (i > 0) while (i-- && !error) error = fprintf(stdout, "<ol>") <= 0;
				if (!error) error = fprintf(stdout, "<li><a href=\"#") <= 0;
				if (!error) error = !echoHeadingIndex(userData, index);
				if (!error) error = fprintf(stdout, "\">") <= 0;
				if (userDataIndexed) {
					if (!error) error = !echoHeadingIndex(userData, index);
					if (!error) error = fprintf(stdout, " ") <= 0;
				}
				if (!error) error = !escapeTextWriter(userData, token->text);
				if (!error) error = fprintf(stdout, "</a></li>") <= 0;
			}
			userDataLastIndex = index;
			break;
		}
		case WIKI_PARSER_TOKEN_TYPE_NONE:
		{
			int index = 1, i;
			i = index - userDataLastIndex;
			if (i < 0) {
				i = -i;
				while (i-- && !error) error = fprintf(stdout, "</ol>") <= 0;
			}
			break;
		}
		default:
			break;
	}
	return !error;
}

bool wikiWriter(void *userData, WikiParserToken *token)
{
	assert(token);
	bool error = false;
	switch (token->type) {
		case WIKI_PARSER_TOKEN_TYPE_BOLD:
			error = fprintf(stdout, token->state ? "<strong>" : "</strong>") <= 0;
			break;
		case WIKI_PARSER_TOKEN_TYPE_CODE:
			error = fprintf(stdout, token->state ? "<code>" : "</code>") <= 0;
			break;
		case WIKI_PARSER_TOKEN_TYPE_DEFINITIONDESC:
			error = fprintf(stdout, token->state ? "<dd>" : "</dd>") <= 0;
			break;
		case WIKI_PARSER_TOKEN_TYPE_DEFINITIONLIST:
			error = fprintf(stdout, token->state ? "<dl>" : "</dl>") <= 0;
			break;
		case WIKI_PARSER_TOKEN_TYPE_DEFINITIONTERM:
			error = fprintf(stdout, token->state ? "<dt>" : "</dt>") <= 0;
			break;
		case WIKI_PARSER_TOKEN_TYPE_HEADING0: /* Not used directly; for calculations. */
		case WIKI_PARSER_TOKEN_TYPE_HEADING1: /* title */
		case WIKI_PARSER_TOKEN_TYPE_HEADING2: /* 1. */
		case WIKI_PARSER_TOKEN_TYPE_HEADING3: /* 1.1. */
		case WIKI_PARSER_TOKEN_TYPE_HEADING4: /* 1.1.1. */
		case WIKI_PARSER_TOKEN_TYPE_HEADING5: /* 1.1.1.1. */
		case WIKI_PARSER_TOKEN_TYPE_HEADING6: /* 1.1.1.1.1. */
		{
			int index = token->type - WIKI_PARSER_TOKEN_TYPE_HEADING0;
			int i = index - 1;
			userDataHeadings[i]++;
			if (!error) error = fprintf(stdout, "<h%d id=\"", index) <= 0;
			if (!error) error = !echoHeadingIndex(userData, index);
			if (!error) error = fprintf(stdout, "\">") <= 0;
			if (!error) error = fprintf(stdout, "<a id=\"") <= 0;
			if (!error) error = !echoHeadingID(userData, token->text);
			if (!error) error = fprintf(stdout, "\" />") <= 0;
			if (userDataIndexed) {
				if (!error) error = !echoHeadingIndex(userData, index);
				if (!error) error = fprintf(stdout, " ") <= 0;
			}
			if (!error) error = !escapeTextWriter(userData, token->text);
			if (!error) error = fprintf(stdout, "</h%d>", index) <= 0;
			break;
		}
		case WIKI_PARSER_TOKEN_TYPE_HORIZONTALRULE:
			error = fprintf(stdout, "<hr />") <= 0;
			break;
		case WIKI_PARSER_TOKEN_TYPE_IMAGE:
			if (!error) error = fprintf(stdout, "<img src=\"") <= 0;
			if (!error) error = !escapeTextWriter(userData, token->source);
			if (token->text) {
				if (!error) error = fprintf(stdout, "\" alt=\"") <= 0;
				if (!error) error = !escapeTextWriter(userData, token->text);
			}
			if (!error) error = fprintf(stdout, "\" />") <= 0;
			break;
		case WIKI_PARSER_TOKEN_TYPE_ITALIC:
			error = fprintf(stdout, token->state ? "<em>" : "</em>") <= 0;
			break;
		case WIKI_PARSER_TOKEN_TYPE_KEYBOARD:
			error = fprintf(stdout, token->state ? "<kbd>" : "</kbd>") <= 0;
			break;
		case WIKI_PARSER_TOKEN_TYPE_LINEBREAK:
			error = fprintf(stdout, "<br />") <= 0;
			break;
		case WIKI_PARSER_TOKEN_TYPE_LINK:
			if (!error) error = fprintf(stdout, "<a href=\"") <= 0;
			if (!error) error = !escapeTextWriter(userData, token->target);
			if (token->target->size == 1 && *token->target->data == '#') { /* Page reference text. */
				if (!error) error = !echoHeadingID(userData, token->text ? token->text : token->target);
			}
			if (!error) error = fprintf(stdout, "\">") <= 0;
			if (token->source) {
				// image inside links hack
				if (!error) error = fprintf(stdout, "<img src=\"") <= 0;
				if (!error) error = !escapeTextWriter(userData, token->source);
				if (!error) error = fprintf(stdout, "\" />") <= 0;
			}
			else {
				if (!error) error = !escapeTextWriter(userData, token->text ? token->text : token->target);
			}
			if (userDataOutlink && *userDataOutlink && (strncmp(token->target->data, "http", 4) == 0 || strncmp(token->target->data, "./", 2) == 0)) { /* HTML markup for outlink. */
				if (!error) error = fprintf(stdout, "%s", userDataOutlink) <= 0;
			}
			if (!error) error = fprintf(stdout, "</a>") <= 0;
			break;
		case WIKI_PARSER_TOKEN_TYPE_LISTITEM:
			error = fprintf(stdout, token->state ? "<li>" : "</li>") <= 0;
			break;
		case WIKI_PARSER_TOKEN_TYPE_ORDEREDLIST:
			error = fprintf(stdout, token->state ? "<ol>" : "</ol>") <= 0;
			break;
		case WIKI_PARSER_TOKEN_TYPE_PARAGRAPH:
			error = fprintf(stdout, token->state ? "<p>" : "</p>") <= 0;
			break;
		case WIKI_PARSER_TOKEN_TYPE_PREFORMATTED:
			if (!error) error = fprintf(stdout, "<pre>") <= 0;
			if (!error) error = !escapeTextWriter(userData, token->text);
			if (!error) error = fprintf(stdout, "</pre>") <= 0;
			break;
		case WIKI_PARSER_TOKEN_TYPE_SAMPLECODE:
			error = fprintf(stdout, token->state ? "<samp>" : "</samp>") <= 0;
			break;
		case WIKI_PARSER_TOKEN_TYPE_SUBSCRIPT:
			error = fprintf(stdout, token->state ? "<sub>" : "</sub>") <= 0;
			break;
		case WIKI_PARSER_TOKEN_TYPE_SUPERSCRIPT:
			error = fprintf(stdout, token->state ? "<sup>" : "</sup>") <= 0;
			break;
		case WIKI_PARSER_TOKEN_TYPE_TABLE:
			error = fprintf(stdout, token->state ? "<table>" : "</table>") <= 0;
			userDataRowCount = 0;
			break;
		case WIKI_PARSER_TOKEN_TYPE_TABLEDATA:
			error = fprintf(stdout, token->state ? "<td>" : "</td>") <= 0;
			break;
		case WIKI_PARSER_TOKEN_TYPE_TABLEHEADER:
			error = fprintf(stdout, token->state ? "<th>" : "</th>") <= 0;
			userDataRowCount = 0;
			break;
		case WIKI_PARSER_TOKEN_TYPE_TABLEROW:
		{
			bool alt = userDataRowCount % 2; /* User data is used to keep track of the row state. */
			error = fprintf(stdout, token->state ? alt ? "<tr class=\"alt\">" : "<tr>" : "</tr>") <= 0;
			if (token->state) userDataRowCount += 1;
			break;
		}
		case WIKI_PARSER_TOKEN_TYPE_TEXT:
			error = !escapeTextWriter(userData, token->text);
			break;
		case WIKI_PARSER_TOKEN_TYPE_UNDERLINE:
			error = fprintf(stdout, token->state ? "<span class=\"underline\">" : "</span>") <= 0;
			break;
		case WIKI_PARSER_TOKEN_TYPE_UNORDEREDLIST:
			error = fprintf(stdout, token->state ? "<ul>" : "</ul>") <= 0;
			break;
		case WIKI_PARSER_TOKEN_TYPE_VARIABLE:
			error = fprintf(stdout, token->state ? "<var>" : "</var>") <= 0;
			break;
		case WIKI_PARSER_TOKEN_TYPE_WIKINOWIKI:
			if (token->state) { /* Render in monospace. */
				if (!error) error = fprintf(stdout, "<code>") <= 0;
				if (!error) error = !escapeTextWriter(userData, token->text);
				if (!error) error = fprintf(stdout, "</code>") <= 0;
			} else {
				if (!error) error = !escapeTextWriter(userData, token->text);
			}
			break;
		case WIKI_PARSER_TOKEN_TYPE_WIKIPLACEHOLDER:
			if (!error) error = fprintf(stdout, "<!--") <= 0;
			if (!error) error = !escapeTextWriter(userData, token->text);
			if (!error) error = fprintf(stdout, "-->") <= 0;
			break;
		case WIKI_PARSER_TOKEN_TYPE_WIKIPLUGIN:
		{
			char *name = createWikiParserString(token->text->data, token->text->size);
			if (name && *name == '$') {
				char *value = getenv(name + 1);
				if (value && *value && !error) error = fprintf(stdout, "%s", value) <= 0;
				wikiParserStringFree(name);
				name = NULL;
			}
			break;
		}
		case WIKI_PARSER_TOKEN_TYPE_NONE:
			/* end of stream */
			break;
		default:
			error = true;
	}
	return !error;
}

int main(int argc, char **argv)
{
	bool aflag = false;
	bool mflag = false;
	bool xflag = false;
	char *bvalue = NULL;
	char *ovalue = NULL;
	WriteTokenFunc writer = wikiWriter;
	int c;
	while ((c = getopt(argc, argv, "ab:mo:w:x")) != -1) {
		switch (c) {
			case 'a': /* Wiki creole additions flag. */
				aflag = true;
				break;
			case 'b': /* Input stream buffer size for testing. */
				bvalue = optarg;
				break;
			case 'm': /* Inline nowiki monospaced flag. */
				mflag = true;
				break;
			case 'o': /* HTML markup for outlink. */
				ovalue = optarg;
				break;
			case 'w': /* Special token writer. */
				if (strcmp(optarg, "title") == 0) writer = wikiTitleWriter;
				else if (strcmp(optarg, "toc") == 0) writer = wikiTOCWriter;
				else fprintf(stderr, "Error: Unknown writer %s\n", optarg);
				break;
			case 'x': /* Indexed content Headings and TOC labels. */
				xflag = true;
				break;
			case '?':
				/* fall through */
			default:
				fprintf(stderr, "Usage: %s [-a] [-b bufferSize] [-m] [-o outlink] [-w writer] [-x]\n", argv[0]);
				return 1;
		}
	}
	WikiParserConfig config = { aflag, false, mflag, NULL, writer };
	WikiParser parser = createWikiParser(&config);
	if (parser) {
		Wiki2HTMLUserData userData;
		int i = MAX_HEADINGS;
		while (i--) userData.headings[i] = 0;
		userData.indexed = xflag;
		userData.lastIndex = 0;
		userData.outlink = ovalue;
		wikiParserSetUserData(parser, &userData);
		size_t size = bvalue ? atoi(bvalue) : WIKI_PARSER_BUFFER_SIZE;
		WikiParserBuffer *buffer = createWikiParserBuffer(size);
		if (buffer) {
			if (!wikiParserParseStream(parser, buffer, wikiReader, 0)) {
				fprintf(stderr, "Error: parser error: %d %s (line %d)\n", 
						wikiParserGetErrorCode(parser), wikiParserGetErrorString(parser), 
						wikiParserGetCurrentLine(parser));
				return 1;
			}
			wikiParserBufferFree(buffer);
			buffer = NULL;
		} else {
			fprintf(stderr, "Error: could not allocate buffer: %lld\n", (long long)buffer->size);
			return 1;
		}
		wikiParserFree(parser);
		parser = NULL;
	} else {
		fprintf(stderr, "Error: could not create parser\n");
		return 1;
	}
	return 0;
}
