/* -*- mode: C -*-
 *
 *       File:         rec-field-new.c
 *       Date:         Fri Nov 12 13:00:24 2010
 *
 *       GNU recutils - rec_field_new unit tests.
 *
 */

/* Copyright (C) 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2020, 2022
 * Jose E. Marchesi */

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
#include <check.h>

#include <rec.h>

/*-
 * Test: rec_field_new_nominal
 * Unit: rec_field_new
 * Description:
 * + Create a field.
 */
START_TEST(rec_field_new_nominal)
{
  const char *fname;
  rec_field_t field;

  fname = "foo";
  field = rec_field_new (fname, "value");
  fail_if (field == NULL);

  rec_field_destroy (field);
}
END_TEST


/*
 * Test creation function
 */
TCase *
test_rec_field_new (void)
{
  TCase *tc = tcase_create ("rec_field_new");
  tcase_add_test (tc, rec_field_new_nominal);

  return tc;
}

/* End of rec-field-new.c */
