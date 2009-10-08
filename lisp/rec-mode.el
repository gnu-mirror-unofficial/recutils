;;; rec-mode.el --- Major mode for viewing/editing rec files

;; Copyright (C) 2009 Jose E. Marchesi

;; Maintainer: Jose E. Marchesi

;; This file is NOT part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:

;; A major mode for editing rec files.

;;; Code:

;; Customization

(defgroup rec-mode nil
  "rec-mode subsystem"
  :group 'applications
  :link '(url-link "http://www.gnu.org/software/rec"))

;; Variables that the user does not want to touch (really)

(defvar rec-comment-re "^#.*$"
  "regexp denoting a comment line")

(defvar rec-field-name-re
  "^\\([a-zA-Z0-1_%-]+:\\)+"
  "Regexp matching a field name")

(defvar rec-field-value-re
  (let ((ret-re "\n\\+ ?")
        (esc-ret-re "\\\\\n"))
    (concat
     "\\("
     "\\(" ret-re "\\)*"
     "\\(" esc-ret-re "\\)*"
     "[^\\\n]*"
     "\\)*"))
  "Regexp matching a field value")

(defvar rec-field-re
  (concat rec-field-name-re
          rec-field-value-re)
  "Regexp matching a field")

(defvar rec-record-re
  (concat rec-field-re "\\(\n" rec-field-re "\\)+")
  "Regexp matching a record")

(defvar rec-record-beginning-re
  (concat "\n\n\\(" rec-comment-re "\\|" rec-field-re "\\)")
  "Regexp matching the beginning of a record")
  
(defvar rec-mode-syntax-table
  (let ((st (make-syntax-table)))
    (modify-syntax-entry ?# "<" st)   ; Comment start
    (modify-syntax-entry ?\n ">" st)  ; Comment end
    st)
  "Syntax table used in rec-mode")

(defvar rec-font-lock-keywords
  `(("^%\\(rec\\|key\\|unique\\|mandatory\\|doc\\):" . font-lock-keyword-face)
    (,rec-field-name-re . font-lock-variable-name-face)
    ("^\\+" . font-lock-constant-face))
  "Font lock keywords used in rec-mode")
  
(defvar rec-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "TAB") 'rec-goto-next-rec)
    (define-key map "\C-ce" 'rec-edit-field)
    map)
  "Keymap for rec-mode")

;; Parsing functions (rec-parse-*)
;;
;; Those functions read the contents of the buffer (starting at the
;; current position of the pointer) and try to parse field, comment
;; and records structures.

(defun rec-parse-comment ()
  "Parse and return a comment starting at point.

Return a list whose first element is the symbol 'comment and the
second element is the string with the contents of the comment,
including the leading #:

   (comment \"# foo\")

If the point is not at the beginning of a comment return nil"
  (when (and (equal (current-column) 0)
             (looking-at rec-comment-re))
    (goto-char (match-end 0))
    (list 'comment (buffer-substring-no-properties (match-beginning 0)
                                                   (match-end 0)))))

(defun rec-parse-field-name ()
  "Parse and return a field name starting at point.

Return a list with whose elements are the parts of the field
name.  For the name a:b:c:d: the following list is returned:

   ('a' 'b' 'c' 'd')

If the point is not at the beginning of a field name return nil"
  (when (and (equal (current-column) 0)
             (looking-at rec-field-name-re))
    (goto-char (match-end 0))
    (split-string
     (buffer-substring-no-properties (match-beginning 0)
                                     (- (match-end 0) 1))
     ":")))

(defun rec-parse-field-value ()
  "Return the field value under the pointer.

Return a string containing the value of the field.

If the pointer is not at the beginning of a field value, return
nil"
  (when (looking-at rec-field-value-re)
    (goto-char (match-end 0))
    (let ((val (buffer-substring-no-properties (match-beginning 0)
                                               (match-end 0))))
      ;; Replace escaped newlines
      (setq val (replace-regexp-in-string "\\\\\n" "" val))
      ;; Replace continuation lines
      (setq val (replace-regexp-in-string "\n\\+ ?" "\n" val))
      ;; Trim blanks in the value
      (setq val (replace-regexp-in-string "^[ \t]+" "" val))
      (setq val (replace-regexp-in-string "[ \t]+$" "" val))
      val)))

(defun rec-parse-field ()
  "Return a structure describing the field starting from the
pointer.

The returned structure is a list whose first element is the
symbol 'field', the second element is the name of the field and
the second element is the value of the field:

   (field FIELD-NAME FIELD-VALUE)

If the pointer is not at the beginning of a field
descriptor then return nil"
  (let (field-name field-value)
    (and (setq field-name (rec-parse-field-name))
         (setq field-value (rec-parse-field-value)))
    (when (and field-name field-value)
        (list 'field field-name field-value))))

(defun rec-parse-record ()
  "Return a structure describing the record starting from the pointer.

The returned structure is a list of fields preceded by the symbol
'record':

   (record FIELD-1 FIELD-2 ... FIELD-N)

If the pointer is not at the beginning of a record, then return
nil"
  (let (record field-or-comment)
    (while (setq field-or-comment (or (rec-parse-field)
                                      (rec-parse-comment)))
      (setq record (cons field-or-comment record))
      ;; Skip the newline finishing the field or the comment
      (when (looking-at "\n") (goto-char (match-end 0))))
    (setq record (cons 'record (reverse record)))))

;; Writer functions (rec-insert-*)
;;
;; Those functions dump the written representation of the parser
;; structures (field, comment, record, etc) into the current buffer
;; starting at the current position.

(defun rec-insert-comment (comment)
  "Insert the written form of COMMENT in the current buffer"
  (when (and (listp comment) 
             (equal (car comment) 'comment))
    (insert (cadr comment) "\n")))

(defun rec-insert-field-name (field-name)
  "Insert the written form of FIELD-NAME in the current buffer"
  (when (listp field-name)
    (mapcar (lambda (elem)
              (when (stringp elem) (insert elem ":")))
            field-name)))

(defun rec-insert-field-value (field-value)
  "Insert the written form of FIELD-VALUE in the current buffer"
  (when (stringp field-value)
    (let ((val field-value))
      ;; FIXME: Maximum line size
      (insert (replace-regexp-in-string "\n" "\n+ " val)))
    (insert "\n")))

(defun rec-insert-field (field)
  "Insert the written form of FIELD in the current buffer"
  (when (and (listp field)
             (equal (car field) 'field))
    (when (rec-insert-field-name (cadr field))
      (insert " ")
      (rec-insert-field-value (nth 2 field)))))

(defun rec-insert-record (record)
  "Insert the written form of RECORD in the current buffer"
  (when (and (listp record)
             (equal (car record) 'record))
    (rec-insert-record-2 (cdr record))))

(defun rec-insert-record-2 (record)
  "Insert the written form of RECORD in the current buffer.
Recursive part"
  (when (and record (listp record))
    (let ((elem (car record)))
      (cond
       ((equal (car elem) 'comment)
        (rec-insert-comment elem))
       ((equal (car elem) 'field)
        (rec-insert-field elem))))
    (rec-insert-record-2 (cdr record))))

;; Operations on record structures
;;
;; Those functions retrieve or set properties of field structures.

(defun rec-record-assoc (name record)
  "Get a list with the values of the fields in RECORD named NAME.  If no such
field exists in RECORD then nil is returned"
  (when (and (listp record)
             (equal (car record) 'record))
    (let (result)
      (mapcar (lambda (field)
                (when (and (equal (car field) 'field)
                           (equal name (cadr field)))
                  (setq result (cons (nth 2 field) result))))
              (cdr record))
      (reverse result))))

(defun rec-record-names (record)
  "Get a list of the field names in the record"
  (when (and (listp record)
             (equal (car record) 'record))
    (let (result)
      (mapcar (lambda (field)
                (when (and (equal (car field) 'field))
                  (setq result (cons (nth 1 field) result))))
              (cdr record))
      (reverse result))))

;; Operations on field structures
;;
;; Those functions retrieve or set properties of field structures.

(defun rec-field-p (field)
  "Determine if the provided structure is a field"
  (and (listp field)
       (= (length field) 3)
       (equal (car field) 'field)))

(defun rec-field-name (field)
  "Return the name of the provided field"
  (when (rec-field-p field)
    (cadr field)))

(defun rec-field-value (field)
  "Return the value of the provided field"
  (when (rec-field-p field)
    (nth 2 field)))

;; Get entities under pointer
;;
;; Those functions retrieve structures of the entities under pointer
;; like comments, fields and records.  If the especified entity is not
;; under the pointer then nil is returned.

(defun rec-current-comment ()
  ""
  )

(defun rec-current-field ()
  "Return a structure with the contents of the current field.
The current field is the field where the pointer is."
  (save-excursion
    (let ((current-point (point)))
      (when (re-search-backward rec-field-re nil t)
        (re-search-forward rec-field-re nil t)
        (when (>= (match-end 0) current-point)
          (goto-char (match-beginning 0))
          (rec-parse-field))))))

(defun rec-current-record ()
  "Return a structure with the contents of the current record.
The current record is the record where the pointer is"
  (save-excursion
    (rec-beginning-of-record)
    (let ((rec (rec-parse-record)))
    (when (> (length rec) 1)
      rec))))

;; Record collection management
;;
;; These functions perform the management of the collection of records
;; in the buffer.  They operate in the buffer local variable
;; `rec-buffer-records'.
    
(defun rec-update-records ()
  "Update the value of the `rec-buffer-records' local variable by
scanning the current buffer.  Recursive step"
  (when (re-search-forward rec-record-beginning-re nil t)
    (let (rec (rec-current-record))
      (if (rec-record-assoc '("%rec") rec)
          ;; Record descriptor
          (reverse (cons (list 'descriptor (rec-record-assoc '("Name") rec)) (rec-update-records)))
        ;; Regular record
        (reverse (cons (list 'record (rec-record-assoc '("Name") rec)) (rec-update-records)))))))

;; Commands
;;
;; The following functions are implementing commands available in the
;; modes.

(defun rec-edit-field ()
  "Edit the contents of the field under point in a separate
buffer"
  (interactive)
  (let (edit-buf
        (field-value (rec-field-value (rec-current-field))))
    (if field-value
        (progn
          (setq edit-buf (get-buffer-create "Rec Edit"))
          (set-buffer edit-buf)
          (rec-edit-field-mode)
          (insert field-value)
          (switch-to-buffer-other-window edit-buf)
          (message "Edit the value of the field and press C-cC-c to exit"))
      (message "Not in a field"))))

(defun rec-beginning-of-field ()
  "Goto to the beginning of the current field"
  (interactive)
  (re-search-backward rec-field-value-re nil t))

(defun rec-end-of-field ()
  "Goto to the end of the current field"
  (interactive)
  (while (or (looking-at rec-field-name-re))
    (goto-char (match-end 0))))

(defun rec-beginning-of-record ()
  "Goto to the beginning of the current record"
  (interactive)
  (let ((current-pos (point))
        (rec-sep-re "^[ \t]*$"))
    (beginning-of-line)
    (while (not (or (= (point) (point-min))
                    (looking-at rec-sep-re)))
      (vertical-motion -1)
      (beginning-of-line))
    (when (not (= (point) current-pos))
      (when (looking-at rec-sep-re)
        (goto-char (+ (match-end 0) 1))))))

(defun rec-end-of-record ()
  "Goto to the end of the current record"
  (interactive)
  (let ((rec-sep-re "^[ \t]*$"))
    (beginning-of-line)
    (while (not (or (= (point) (point-max))
                    (looking-at rec-sep-re)))
      (vertical-motion 1)
      (beginning-of-line))))

;; Definition of modes
  
(defun rec-mode ()
  "A major mode for editing rec files.

Commands:
\\{rec-mode-map}"
  (interactive)
  (kill-all-local-variables)
  (make-local-variable 'font-lock-defaults)
  (setq font-lock-defaults '(rec-font-lock-keywords))
  (use-local-map rec-mode-map)
  (set-syntax-table rec-mode-syntax-table)
  (setq mode-name "Rec")
  (make-local-variable 'rec-buffer-records)
  (setq major-mode 'rec-mode))

(defvar rec-edit-field-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map "\C-c\C-c" 'rec-finish-editing-field)
    map)
  "Keymap for rec-edit-field-mode")

(defun rec-edit-field-mode ()
  "A major mode for editing rec field values.

Commands:
\\{rec-edit-field-mode-map}"
  (interactive)
  (kill-all-local-variables)
  (use-local-map rec-edit-field-mode-map)
  (setq mode-name "Rec Edit")
  (setq major-mode 'rec-edit-field-mode))

;;; rec-mode.el ends here
