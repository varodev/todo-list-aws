python3 -m venv pyenvunittests
source pyenvunittests/bin/activate
python3 -m pip install --upgrade pip
python3 -m pip install boto3
python3 -m pip install moto==3.1
python3 -m pip install mock==4.0.2
python3 -m pip install coverage==4.5.4
export PYTHONPATH="$(pwd)"
export DYNAMODB_TABLE=todoUnitTestsTable
python test/unit/TestToDo.py