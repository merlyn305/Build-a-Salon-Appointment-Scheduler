#! /bin/bash

run_sql() {
  local query="$1"
  shift
  printf '%s\n' "$query" | psql --username=freecodecamp --dbname=salon --no-align --tuples-only --quiet -X "$@"
}

show_services() {
  run_sql "SELECT service_id || ') ' || name FROM services ORDER BY service_id;"
}

printf '\n~~~~~ MY SALON ~~~~~\n\n'
printf 'Welcome to My Salon, how can I help you?\n\n'

show_services
while true; do
  read SERVICE_ID_SELECTED || exit 0
  SERVICE_NAME=$(run_sql "SELECT name FROM services WHERE service_id::text = :'service_id';" -v service_id="$SERVICE_ID_SELECTED")
  if [[ -n "$SERVICE_NAME" ]]; then
    break
  fi

  printf '\nI could not find that service. What would you like today?\n'
  show_services
done

printf "\nWhat's your phone number?\n"
read CUSTOMER_PHONE || exit 0

CUSTOMER_ID=$(run_sql "SELECT customer_id FROM customers WHERE phone = :'customer_phone';" -v customer_phone="$CUSTOMER_PHONE")
if [[ -z "$CUSTOMER_ID" ]]; then
  printf "\nI don't have a record for that phone number, what's your name?\n"
  read CUSTOMER_NAME || exit 0
  CUSTOMER_ID=$(run_sql \
    "INSERT INTO customers (name, phone) VALUES (:'customer_name', :'customer_phone') RETURNING customer_id;" \
    -v customer_name="$CUSTOMER_NAME" \
    -v customer_phone="$CUSTOMER_PHONE" \
  )
else
  CUSTOMER_NAME=$(run_sql "SELECT name FROM customers WHERE customer_id = :'customer_id';" -v customer_id="$CUSTOMER_ID")
fi

printf '\nWhat time would you like your %s, %s?\n' "$SERVICE_NAME" "$CUSTOMER_NAME"
read SERVICE_TIME || exit 0

run_sql \
  "INSERT INTO appointments (customer_id, service_id, time) VALUES (:'customer_id', :'service_id', :'service_time');" \
  -v customer_id="$CUSTOMER_ID" \
  -v service_id="$SERVICE_ID_SELECTED" \
  -v service_time="$SERVICE_TIME"

printf '\nI have put you down for a %s at %s, %s.\n' "$SERVICE_NAME" "$SERVICE_TIME" "$CUSTOMER_NAME"
