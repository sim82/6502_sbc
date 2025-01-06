%start Block
%avoid_insert "INT"
%%

Block -> Result<Block, Error>:
	Statement {
		$1.map( |x| Block(vec!(x)) )
	}
	| Block Statement { 
		let Block(mut statements) = $1?;
		statements.push($2?);
		Ok(Block(statements))
	}
	;

Statement -> Result<Statement, Error>:
	'IDENTIFIER' '=' Expression ';'{
		Ok(
			Statement::Assignment {
				identifier: $1?.span(),
				expression: $3?,
			}
		)
	}
	| 'print' 'IDENTIFIER' ';' {
		Ok(
			Statement::TestCall {
				function: $1?.span(),
				identifier: $2?.span(),
			}
		)
	}
	;

Expression -> Result<Expression, Error>: 
	Expression '+' Product {
		Ok(
			Expression::Sum {
				a: Box::new($1?),
				b: Box::new($3?),
			}
		)
	} 
	| Product {
		$1
	}
    ;
Product -> Result<Expression, Error>:
	Product '*' Term {
		
		Ok(
			Expression::Product {
				a: Box::new($1?),
				b: Box::new($3?),
			}
		)
	}
	| Term {
		$1
	} 
    ;

Term -> Result<Expression, Error>:
	'INT' {
		
		Ok(
			Expression::Constant(
				parse_int(
					$lexer.span_str($1?.span())
				)?
			)

		)
	}
	| 'IDENTIFIER' {
		Ok(
			Expression::Load($1?.span())
		)
	}
	| '(' Expression ')' {
		$2
	}
	;

%%
use anyhow::Error;
use anyhow::anyhow;
use cfgrammar::Span;

#[derive(Debug)]
pub struct Block(Vec<Statement>);

#[derive(Debug)]
pub struct File(i32);

#[derive(Debug)]
pub enum Statement {
	Assignment {
		identifier: Span,
		expression: Expression,
	},
	TestCall {
		function: Span,
		identifier: Span,
		// expression: Expression,
	}
}
#[derive(Debug)]
pub enum Expression {
	Constant(i32),
	Load(Span),
	Sum {
		a: Box<Expression>,
		b: Box<Expression>,
	},
	Product {
		a: Box<Expression>,
		b: Box<Expression>,
	}
}


fn parse_int(s: &str) -> Result<i32, Error> {
    match s.parse::<i32>() {
        Ok(val) => Ok(val),
        Err(_) => {
            Err(anyhow!("{} cannot be represented as a i32", s))
        }
    }
}
fn flatten<T>(lhs: Result<Vec<T>, Error>, rhs: Result<T, Error>)
           -> Result<Vec<T>, Error>
{
    let mut flt = lhs?;
    flt.push(rhs?);
    Ok(flt)
}
