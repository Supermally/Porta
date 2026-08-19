use std::collections::HashMap;

#[derive(Debug, Clone, PartialEq)]
pub enum VdfValue {
    String(String),
    Obj(HashMap<String, VdfValue>),
}

impl VdfValue {
    pub fn as_str(&self) -> Option<&str> {
        match self {
            VdfValue::String(s) => Some(s),
            _ => None,
        }
    }

    pub fn as_obj(&self) -> Option<&HashMap<String, VdfValue>> {
        match self {
            VdfValue::Obj(map) => Some(map),
            _ => None,
        }
    }

    pub fn get_path(&self, keys: &[&str]) -> Option<&VdfValue> {
        let mut curr = self;
        for key in keys {
            match curr {
                VdfValue::Obj(map) => {
                    curr = map.get(*key)?;
                }
                _ => return None,
            }
        }
        Some(curr)
    }
}

pub struct VdfParser;

impl VdfParser {
    pub fn parse(input: &str) -> Result<HashMap<String, VdfValue>, String> {
        let mut tokens = Self::tokenize(input);
        tokens.reverse(); // So we can pop from the end
        let mut root = HashMap::new();

        while !tokens.is_empty() {
            if let Some((k, v)) = Self::parse_pair(&mut tokens)? {
                root.insert(k, v);
            }
        }

        Ok(root)
    }

    fn tokenize(input: &str) -> Vec<String> {
        let mut tokens = Vec::new();
        let mut chars = input.chars().peekable();

        while let Some(&c) = chars.peek() {
            if c.is_whitespace() {
                chars.next();
                continue;
            }

            if c == '/' {
                chars.next();
                if chars.peek() == Some(&'/') {
                    // Line comment, consume till newline
                    while let Some(ch) = chars.next() {
                        if ch == '\n' {
                            break;
                        }
                    }
                    continue;
                }
            }

            if c == '{' || c == '}' {
                chars.next();
                tokens.push(c.to_string());
                continue;
            }

            if c == '"' {
                chars.next();
                let mut s = String::new();
                let mut escaped = false;
                while let Some(ch) = chars.next() {
                    if escaped {
                        s.push(ch);
                        escaped = false;
                    } else if ch == '\\' {
                        escaped = true;
                    } else if ch == '"' {
                        break;
                    } else {
                        s.push(ch);
                    }
                }
                tokens.push(s);
                continue;
            }

            // Bare word
            let mut s = String::new();
            while let Some(&ch) = chars.peek() {
                if ch.is_whitespace() || ch == '{' || ch == '}' || ch == '"' {
                    break;
                }
                s.push(ch);
                chars.next();
            }
            if !s.is_empty() {
                tokens.push(s);
            }
        }

        tokens
    }

    fn parse_pair(tokens: &mut Vec<String>) -> Result<Option<(String, VdfValue)>, String> {
        let key = match tokens.pop() {
            Some(k) => {
                if k == "}" {
                    return Ok(None);
                }
                k
            }
            None => return Ok(None),
        };

        let next = tokens.last().cloned().ok_or_else(|| "Unexpected EOF after key".to_string())?;

        if next == "{" {
            tokens.pop(); // consume '{'
            let mut map = HashMap::new();
            while let Some(pair) = Self::parse_pair(tokens)? {
                map.insert(pair.0, pair.1);
            }
            Ok(Some((key, VdfValue::Obj(map))))
        } else {
            let val = tokens.pop().unwrap();
            Ok(Some((key, VdfValue::String(val))))
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_vdf_parser() {
        let sample = r#"
"AppState"
{
    "appid"     "1245620"
    "name"      "ELDEN RING"
    "installdir" "ELDEN RING"
    "UserConfig"
    {
        "language" "english"
    }
}
"#;
        let parsed = VdfParser::parse(sample).unwrap();
        let app_state = parsed.get("AppState").unwrap().as_obj().unwrap();
        assert_eq!(app_state.get("appid").unwrap().as_str(), Some("1245620"));
        assert_eq!(app_state.get("name").unwrap().as_str(), Some("ELDEN RING"));
    }
}
