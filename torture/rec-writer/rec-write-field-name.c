/* -*- mode: C -*- Time-stamp: "2010-11-14 15:06:53 jemarch"
 *
 *       File:         rec-write-field-name.c
 *       Date:         Sun Nov 14 11:32:17 2010
 *
 *       GNU recutils - rec_write_field_name unit tests.
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

#include <config.h>
#include <string.h>
#include <stdio.h>
#include <check.h>

#include <rec.h>

/*-
 * Test: rec_write_field_name_nominal
 * Unit: rec_write_field_name
 * Description:
 * + Write field names.
 */
START_TEST(rec_write_field_name_nominal)
{
  rec_writer_t writer;
  rec_field_name_t fname;
  FILE *stm;
  char *str;
  size_t str_size;

  fname = rec_field_name_new ();
  fail_if (fname == NULL);
  rec_field_name_set (fname, 0, "foo");
  rec_field_name_set (fname, 1, "bar");
  rec_field_name_set (fname, 2, "baz");
  stm = open_memstream (&str, &str_size);
  writer = rec_writer_new (stm);
  fail_if (stm == NULL);
  fail_if (!rec_write_field_name (writer, fname, REC_WRITER_NORMAL));
  rec_field_name_destroy (fname);
  rec_writer_destroy (writer);
  fclose (stm);
  fail_if (strcmp (str, "foo:bar:baz:") != 0);
}
END_TEST

/*-
 * Test: rec_write_field_name_sexp
 * Unit: rec_write_field_name
 * Description:
 * + Write field names.
 */
START_TEST(rec_write_field_name_sexp)
{
  rec_writer_t writer;
  rec_field_name_t fname;
  FILE *stm;
  char *str;
  size_t str_size;

  fname = rec_field_name_new ();
  fail_if (fname == NULL);
  rec_field_name_set (fname, 0, "foo");
  rec_field_name_set (fname, 1, "bar");
  rec_field_name_set (fname, 2, "baz");
  stm = open_memstream (&str, &str_size);
  writer = rec_writer_new (stm);
  fail_if (stm == NULL);
  fail_if (!rec_write_field_name (writer, fname, REC_WRITER_SEXP));
  rec_field_name_destroy (fname);
  rec_writer_destroy (writer);
  fclose (stm);
  fail_if (strcmp (str, "(\"foo\" \"bar\" \"baz\")") != 0);
}
END_TEST

/*
 * Test creation function
 */
TCase *
test_rec_write_field_name (void)
{
  TCase *tc = tcase_create ("rec_write_field_name");
  tcase_add_test (tc, rec_write_field_name_nominal);
  tcase_add_test (tc, rec_write_field_name_sexp);

  return tc;
}

/* End of rec-write-field-name.c */