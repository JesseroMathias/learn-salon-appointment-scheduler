#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=salon --tuples-only -c"

echo -e "\n~~~~~ MY SALON ~~~~~\n"
echo -e "Welcome to My Salon, how can I help you?\n"

CUSTOMER_NAME=""
CUSTOMER_PHONE=""
SERVICES=$($PSQL "SELECT service_id, name FROM services ORDER BY service_id")

# Function to create an appointment
CREATE_APPOINTMENT() {
  # Get service name
  SERVICE_NAME=$($PSQL "SELECT name FROM services WHERE service_id=$SERVICE_ID_SELECTED")
  # Get customer details
  CUST_NAME=$($PSQL "SELECT name FROM customers WHERE phone='$CUSTOMER_PHONE'")
  CUST_ID=$($PSQL "SELECT customer_id FROM customers WHERE phone='$CUSTOMER_PHONE'")

  # Remove extra spaces for formatting output
  SERVICE_NAME_FORMATTED=$(echo "$SERVICE_NAME" | sed 's/^[ \t]*//;s/[ \t]*$//')
  CUST_NAME_FORMATTED=$(echo "$CUST_NAME" | sed 's/^[ \t]*//;s/[ \t]*$//')

  echo -e "\nWhat time would you like your $SERVICE_NAME_FORMATTED, $CUST_NAME_FORMATTED?"
  read SERVICE_TIME

  # Insert the appointment into the database
  INSERTED=$($PSQL "INSERT INTO appointments(customer_id, service_id, time) VALUES($CUST_ID, $SERVICE_ID_SELECTED, '$SERVICE_TIME')")

  # Confirmation message
  if [[ $INSERTED == "INSERT 0 1" ]]; then
    echo -e "\nI have put you down for a $SERVICE_NAME_FORMATTED at $SERVICE_TIME, $CUST_NAME_FORMATTED."
  else
    echo -e "\nSomething went wrong while creating the appointment."
  fi
}

# Function to handle the main menu
MAIN_MENU() {
  echo -e "\nWhat's your phone number?"
  read CUSTOMER_PHONE

  # Check if the customer exists
  HAVE_CUST=$($PSQL "SELECT customer_id, name FROM customers WHERE phone='$CUSTOMER_PHONE'")

  # If customer doesn't exist, ask for their name and add them to the database
  if [[ -z $HAVE_CUST ]]; then
    echo -e "\nI don't have a record for that phone number, what's your name?"
    read CUSTOMER_NAME
    INSERTED=$($PSQL "INSERT INTO customers(name, phone) VALUES('$CUSTOMER_NAME', '$CUSTOMER_PHONE')")

    if [[ $INSERTED == "INSERT 0 1" ]]; then
      echo -e "\nCustomer $CUSTOMER_NAME added to the database."
      CREATE_APPOINTMENT
    else
      echo -e "\nCould not add customer to the database."
    fi
  else
    # Customer exists, proceed with appointment creation
    CREATE_APPOINTMENT
  fi
}

# Function to list services and allow the user to choose one
LIST_SERVICES() {
  if [[ $1 ]]; then
    echo -e "\n$1"
  fi

  # Display available services
  echo "$SERVICES" | while read SERVICE_ID BAR NAME; do
    echo "$SERVICE_ID) $NAME"
  done

  # Prompt user to select a service
  read SERVICE_ID_SELECTED

  # Validate service selection (must be a number)
  if [[ ! $SERVICE_ID_SELECTED =~ ^[0-9]+$ ]]; then
    LIST_SERVICES "I could not find that service. What would you like today?"
  else
    HAVE_SERVICE=$($PSQL "SELECT service_id FROM services WHERE service_id=$SERVICE_ID_SELECTED")
    if [[ -z $HAVE_SERVICE ]]; then
      LIST_SERVICES "I could not find that service. What would you like today?"
    else
      MAIN_MENU
    fi
  fi
}

# Start the script by listing services
LIST_SERVICES
