/* -*- mode: C -*-
 *
 *       File:         rec-utils.h
 *       Date:         Fri Apr  9 19:42:52 2010
 *
 *       GNU recutils - Miscellanea utilities
 *
 */

/* Copyright (C) 2010 Jose E. Marchesi */

/* This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#ifndef REC_UTILS_H
#define REC_UTILS_H

#include <config.h>

#include <rec.h>
#include <stdbool.h>

enum rec_size_condition_e
  {
    SIZE_COND_E,
    SIZE_COND_L,
    SIZE_COND_LE,
    SIZE_COND_G,
    SIZE_COND_GE
  };

/* Non public constants used by several modules.  */

#define REC_INT_SIZE_RE "^[ \t\n]*(>|<|>=|<=)?[ \t\n]*([0-9]+)[ \t\n]*$"

/* Parse an integer/real in the NULL-terminated string STR and store
   it at NUMBER.  Return true if the conversion was successful.  false
   otherwise. */
bool rec_atoi (char *str, int *number);
bool rec_atod (char *str, double *number);

/* Extract type and url from a %rec: field value.  */
char *rec_extract_url (char *str);
char *rec_extract_file (char *str);
char *rec_extract_type (char *str);

/* Extract size and condition from a %size: field value.  */
size_t rec_extract_size (char *str);
enum rec_size_condition_e rec_extract_size_condition (char *str);

/* Matching a string against a regexp.  */
bool rec_match (char *str, char *regexp);

/* Generic parsing routines.  */
bool rec_blank_p (char c);
bool rec_digit_p (char c);
bool rec_letter_p (char c);
bool rec_parse_int (char **str, int *num);
void rec_skip_blanks (char **str);
bool rec_parse_regexp (char **str, char *re, char **result);

/* Miscellanea.  */
int rec_timespec_subtract (struct timespec *result,
                           struct timespec *x,
                           struct timespec *y);

#endif /* rec-utils.h */

/* End of rec-utils.h.  */
