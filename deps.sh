python3 -m pip install --upgrade pip
python3 -m pip install boto3
python3 -m pip install moto==3.1
python3 -m pip install mock==4.0.2
python3 -m pip install coverage==4.5.4
python3 -m pip install flake8 bandit
export PYTHONPATH="$(pwd)"
export DYNAMODB_TABLE=todoUnitTestsTable