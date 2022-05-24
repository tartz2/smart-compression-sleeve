int bicepReps;
int tricepReps;

void setup() 
{
  Serial.begin(115200);
  while (!Serial); // optionally wait for serial terminal to open
  Serial.println("MyoWare Example_01_analogRead_SINGLE");
}

void loop() 
{  
  int flexSensor = analogRead(A1); 
  int sensorValue = analogRead(A5); // read the input on analog pin A5 -  biceps
  int sensor2Value = analogRead(A3); // read the input on analog pin A3 - triceps
  
  flexSensor = map(flexSensor, 750, 850, 0, 100);
  Serial.print("Flex: ");
  Serial.println(flexSensor);

  String isBicepFlexed = "no";
  String isTricepFlexed = "no";

  if(flexSensor > 15 && sensorValue > 400){
     bicepReps++;
     isBicepFlexed = "yes";
     isTricepFlexed = "no";
  }
  else if(flexSensor <= 15 && sensor2Value > 400){
     tricepReps++;
     isBicepFlexed = "no";
     isTricepFlexed = "yes";
  }

  Serial.print("Bicep Reps: ");
  Serial.println(bicepReps);
  Serial.print("Tricep Reps: ");
  Serial.println(tricepReps);
  Serial.println("Is bicep flexed: " + isBicepFlexed);
  Serial.println("Is tricep flexed: " + isTricepFlexed);
  
  Serial.print("Bicep: ");
  Serial.println(sensorValue); // print out the value you read
  delay(25);
  Serial.print("Tricep: ");
  Serial.println(sensor2Value);
  delay(25);
  

  delay(1000); // to avoid overloading the serial terminal
}
