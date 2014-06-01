/*

C wiki parser library and sample application.

Copyright (c) 2010, Mark Wharton
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

- Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

- Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

*/
#ifndef _RAGELSTUFF_H                        /* duplication check */
#define _RAGELSTUFF_H

#if defined(__cplusplus)
#define __RAGELSTUFF_CLINKAGEBEGIN extern "C" {
#define __RAGELSTUFF_CLINKAGEEND }
#else
#define __RAGELSTUFF_CLINKAGEBEGIN
#define __RAGELSTUFF_CLINKAGEEND
#endif
__RAGELSTUFF_CLINKAGEBEGIN

// struct FiniteStateMachineStruct {
// 	int act;
// 	int cs;
// 	const char *ts;
// 	const char *te;
// 	int stack[32];
// 	int top;
// } fsm;
//
// Requirements:
// bool error defined
// err ## _BUFFER, _PARSE, _READER errors
// name ## _error ragel machine state
// name ## _first_final ragel machine state
// name ## Buffer (e.g. WikiParserBuffer) type exists
// parameters: data, parser, buffer, reader, string exists
// parserError, parserMarker, parserUserData macros exist and, 
// parserFSM macro exists with cs, ts, and te members (see fsm above)

typedef struct ExecPrivateBlockDataStruct {
	const char *p;
	const char *pe;
	const char *eof;
} ExecPrivateBlockData, *ExecPrivateBlockDataPtr;

// http://www.cprogramming.com/tutorial/cpreprocessor.html

// Note: This only works for scanners. We need another method for pure state machines.

#define RAGEL_PARSE_STREAM(exec,name,err,max) \
	do { \
		size_t have = 0; \
		bool done = false; \
		while (!done) { \
			size_t space = buffer->size - have; \
			if (space == 0) { \
				parserError = err ## _BUFFER; \
				error = true; \
				break; \
			} \
			ExecPrivateBlockData data; \
			data.p = buffer->data + have; \
			name ## Buffer read; \
			read.data = data.p; \
			read.size = space; \
			if (!reader(parserUserData, &read, &read.size)) { \
				parserError = err ## _READER; \
				error = true; \
				break; \
			} \
			data.pe = data.p + read.size; \
			data.eof = NULL; \
			if (read.size == 0) { \
				data.eof = data.pe; \
				done = true; \
			} \
			exec(parser, &data); \
			if (parserFSM.cs == name ## _error) { \
				parserError = err ## _PARSER; \
				error = true; \
				break; \
			} else if (parserError) { \
				error = true; \
				break; \
			} \
			if (parserFSM.ts == 0) { \
				have = 0; \
			} else { \
				for (int index = 0; index < max; index++) { \
					if (parserMarker[index]) { \
						size_t shift = parserMarker[index] - parserFSM.ts; \
						parserMarker[index] = buffer->data + shift; \
					} \
				} \
				have = data.pe - parserFSM.ts; \
				memmove((char *)buffer->data, parserFSM.ts, have); \
				parserFSM.te = buffer->data + (parserFSM.te - parserFSM.ts); \
				parserFSM.ts = buffer->data; \
			} \
		} \
	} while (false)

#define RAGEL_PARSE_STRING(exec,name,err,max) \
	do { \
		ExecPrivateBlockData data; \
		data.p = string; \
		data.pe = string + strlen(string); \
		data.eof = data.pe; \
		exec(parser, &data); \
		if ((parserFSM.cs == name ## _error) || (parserFSM.cs < name ## _first_final)) { \
			parserError = err ## _PARSER; \
			error = true; \
		} else if (parserError) { \
			error = true; \
		} \
	} while (false)

#define RAGEL_WRITE_INIT_PREP(max) \
	do { \
		for (int index = 0; index < max; index++) { \
			parserMarker[index] = NULL; \
		} \
	} while (false)

#define RAGEL_WRITE_EXEC_IN() \
	const char *p = ((ExecPrivateBlockDataPtr)data)->p; \
	const char *pe = ((ExecPrivateBlockDataPtr)data)->pe; \
	const char *eof = ((ExecPrivateBlockDataPtr)data)->eof

#define RAGEL_WRITE_EXEC_OUT() \
	((ExecPrivateBlockDataPtr)data)->p = p; \
	((ExecPrivateBlockDataPtr)data)->pe = pe; \
	((ExecPrivateBlockDataPtr)data)->eof = eof

__RAGELSTUFF_CLINKAGEEND
#endif                                   /* duplication check */

/* END OF FILE */
