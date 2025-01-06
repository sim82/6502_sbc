use bs02::{
    diagnostic::{DiagnosticDesc, ErrorReporter},
    parser::{self, lexerdef},
};
use lrpar::{LexError, Lexeme, Span};

fn main() {
    let input = r#"
        a = (666 + 123) * a; 
        b = a + 1; 
        print a;
    "#;
    let error_reporter = ErrorReporter::new("input.bs02", &input);
    let lexerdef = lexerdef();
    let lexer = lexerdef.lexer(&input);
    let (res, errs) = parser::parse(&lexer);
    for e in &errs {
        match e {
            // lrpar::LexParseError::LexError(e) => println!("lex error: {:?}", e),
            // lrpar::LexParseError::ParseError(e) => println!("parse error: {:?}", e),
            lrpar::LexParseError::LexError(le) => {
                // println!("{}", e.pp(&lexer, &parser::token_epp))
                let s: Span = le.span();
                error_reporter.report_diagnostic(&DiagnosticDesc::LexError {
                    label: "here".into(),
                    span: s,
                    note: e.pp(&lexer, &parser::token_epp),
                });
            }
            lrpar::LexParseError::ParseError(pe) => {
                let s: Span = pe.lexeme().span();

                error_reporter.report_diagnostic(&DiagnosticDesc::ParseError {
                    label: "here".into(),
                    span: s,
                    note: e.pp(&lexer, &parser::token_epp),
                });
            }
        }
    }
    if let Some(Ok(res)) = res {
        println!("res: {:?}", res);
    }
}
