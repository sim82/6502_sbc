use bs02::{
    codegen::Codegen,
    diagnostic::{DiagnosticDesc, ErrorReporter},
    parser::{self, lexerdef},
};
use lrpar::{LexError, Lexeme, Span};

fn main() {
    let input = r#"
        a = 8447;
        b = 8550; 
    loop:
        a = a + 1; 
        print a;
        if a != b {
            goto loop;
        }
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
        let mut codegen = Codegen::default();
        if let Err(e) = codegen.generate(&res, input.as_bytes()) {
            panic!("codegen failed: {:?}", e);
        }
        std::fs::write("out.bs02", codegen.get_code()).unwrap();
    }
}
