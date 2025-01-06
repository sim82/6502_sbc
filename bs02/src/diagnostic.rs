use std::collections::HashSet;

use codespan_reporting::{
    diagnostic::{Diagnostic, Label},
    files::SimpleFiles,
    term::{
        self,
        termcolor::{ColorChoice, StandardStream},
    },
};
use levenshtein::levenshtein;
use lrpar::Span;

pub enum DiagnosticDesc {
    ParseError {
        label: String,
        span: Span,
        note: String,
    },
    LexError {
        label: String,
        span: Span,
        note: String,
    },
    UndefinedReference {
        span: Span,
        identifier: String,
    },
    // UndefinedReferenceQualified {
    //     label: String,
    //     span: Span,
    //     identifier_ns: Span,
    //     identifier: Span,
    // },
}

pub struct ErrorReporter {
    files: SimpleFiles<String, String>,
    file_id: usize,
    known_identifier: HashSet<String>,
}
impl ErrorReporter {
    pub fn new(filename: &str, input: &str) -> Self {
        let mut files = SimpleFiles::new();
        let file_id = files.add(filename.into(), input.into());
        ErrorReporter {
            files,
            file_id,
            known_identifier: HashSet::new(),
        }
    }
    fn report_error(&self, message: &str, label: &str, span: Span, note: &str) {
        let diagnostic = Diagnostic::error();
        self.report_internal(span, label, diagnostic, message, note);
    }
    fn report_warning(&self, message: &str, label: &str, span: Span, note: &str) {
        let diagnostic = Diagnostic::warning();
        self.report_internal(span, label, diagnostic, message, note);
    }

    fn report_internal(
        &self,
        span: Span,
        label: &str,
        diagnostic: Diagnostic<usize>,
        message: &str,
        note: &str,
    ) {
        let label = Label::primary(self.file_id, span.start()..span.end()).with_message(label);
        let diagnostic = diagnostic
            .with_message(message)
            .with_labels(vec![label])
            .with_notes(vec![note.into()]);
        let writer = StandardStream::stderr(ColorChoice::Always);
        let config = codespan_reporting::term::Config::default();

        term::emit(&mut writer.lock(), &config, &self.files, &diagnostic).unwrap();
    }
    pub fn report_diagnostic(&self, diagnostic: &DiagnosticDesc) {
        match diagnostic {
            DiagnosticDesc::ParseError { label, span, note } => {
                self.report_error("parse error", label, *span, note)
            }
            DiagnosticDesc::LexError { label, span, note } => {
                self.report_error("lex error", label, *span, note)
            }
            DiagnosticDesc::UndefinedReference { span, identifier } => self.report_error(
                "undefined reference",
                &format!("undefined: {identifier}"),
                *span,
                &self.suggest_identifier(identifier),
            ),
            // DiagnosticDesc::UndefinedReferenceQualified {
            //     label,
            //     span,
            //     identifier_ns,
            //     identifier,
            // } => self.report_error(
            //     "undefined reference",
            //     &format!("undefined: {identifier}"),
            //     *span,
            //     &self.suggest_identifier(identifier),
            // ),
        }
    }
    fn suggest_identifier(&self, identifier: &str) -> String {
        if let Some(m) = self.get_fuzzy_match(identifier) {
            format!("did you mean '{m}'")
        } else {
            "no similar known identifier".into()
        }
    }
    fn get_fuzzy_match(&self, s: &str) -> Option<&str> {
        let mut best = None;
        let mut best_score = usize::MAX;
        for candidate in &self.known_identifier {
            let score = levenshtein(s, candidate);
            if score < best_score {
                best = Some(candidate.as_str());
                best_score = score;
            }
        }
        best
    }

    fn add_identifiers<'a>(&mut self, keys: impl IntoIterator<Item = &'a str>) {
        for identifier in keys.into_iter() {
            self.known_identifier.insert(identifier.into());
        }
    }
    fn check_identifier(&self, identifier: &str, span: Span) {
        if !self.known_identifier.contains(identifier) {
            self.report_diagnostic(&DiagnosticDesc::UndefinedReference {
                span,
                identifier: identifier.into(),
            })
        }
    }
}
