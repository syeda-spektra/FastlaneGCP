## MetaData
Question Type : Single Choice

## Question
2. A customer asks for the balance of HB-99999, which does not exist. What should get_account_balance do?

## Options
Option 1 : Raise an exception, so ADK stops the conversation.

Option 2 : Return the balance of the closest matching account.

Option 3 : Return {"status": "error", "error_code": "ACCOUNT_NOT_FOUND", "message": ...} so Holly can reply kindly without an amount.

Option 4 : Return {"status": "success", "balance": 0}.

## Answers
Option 3 : 3

## Number of Retries
1
