#!/usr/bin/env python3

import os
import random
import string
import json
import datetime
import csv


def generate_random_string(length, charset=string.ascii_letters):
    """Generate a random string of given length and character set."""
    return ''.join(random.choice(charset) for _ in range(length))


def generate_random_number(min_value, max_value):
    """Generate a random number within the specified range."""
    return random.randint(min_value, max_value)


def generate_random_date(start_date, end_date):
    """Generate a random date within the specified range."""
    time_between_dates = end_date - start_date
    days_between_dates = time_between_dates.days
    random_number_of_days = random.randrange(days_between_dates)
    random_date = start_date + datetime.timedelta(days=random_number_of_days)
    return random_date.strftime("%Y-%m-%d")


def generate_sql_insert(table_name, columns, num_records):
    """Generate SQL INSERT statements for populating a table."""
    sql_statements = []
    for _ in range(num_records):
        values = [f"'{generate_random_string(int(input(f'Enter length for {column}: ')))}'" for column in columns]
        sql = f"INSERT INTO {table_name} ({', '.join(columns)}) VALUES ({', '.join(values)});"
        sql_statements.append(sql)
    return sql_statements


def generate_placeholder_data(num_records, data_format):
    """Generate placeholder data based on user-defined format."""
    placeholder_data = []
    for _ in range(num_records):
        record = {}
        for field, field_data in data_format.items():
            data_type = field_data['type']
            if data_type == 'string':
                length = field_data['length']
                charset = field_data['charset']
                record[field] = generate_random_string(length, charset)
            elif data_type == 'number':
                min_value = field_data['min']
                max_value = field_data['max']
                record[field] = generate_random_number(min_value, max_value)
            elif data_type == 'date':
                start_date = datetime.datetime.strptime(field_data['start_date'], "%Y-%m-%d")
                end_date = datetime.datetime.strptime(field_data['end_date'], "%Y-%m-%d")
                record[field] = generate_random_date(start_date, end_date)
            elif data_type == 'boolean':
                record[field] = random.choice([True, False])
        placeholder_data.append(record)
    return placeholder_data


def get_data_format_from_user():
    """Prompt the user for data format preferences."""
    data_format = {}
    while True:
        field = input("Enter field name (or 'done' to finish): ").strip()
        if field.lower() == 'done':
            break

        data_type = input(f"Enter data type for '{field}' (string/number/date/boolean): ").strip()
        if data_type not in ['string', 'number', 'date', 'boolean']:
            print("Invalid data type. Please enter 'string', 'number', 'date', or 'boolean'.")
            continue

        if data_type == 'string':
            length = int(input(f"Enter length for '{field}' (integer): "))
            charset = input(f"Enter character set for '{field}' (optional, press Enter for default): ").strip()
            if not charset:
                charset = string.ascii_letters
            data_format[field] = {'type': 'string', 'length': length, 'charset': charset}
        elif data_type == 'number':
            min_value = int(input(f"Enter minimum value for '{field}' (integer): "))
            max_value = int(input(f"Enter maximum value for '{field}' (integer): "))
            data_format[field] = {'type': 'number', 'min': min_value, 'max': max_value}
        elif data_type == 'date':
            start_date = input(f"Enter start date for '{field}' (YYYY-MM-DD): ")
            end_date = input(f"Enter end date for '{field}' (YYYY-MM-DD): ")
            data_format[field] = {'type': 'date', 'start_date': start_date, 'end_date': end_date}
        elif data_type == 'boolean':
            data_format[field] = {'type': 'boolean'}

    return data_format


def get_file_type_from_user():
    """Prompt the user for the desired file type (e.g., JSON, CSV, SQL, TXT, MD, HTML)."""
    while True:
        file_type = input("Enter the desired file type for saving the data (json/csv/sql/txt/md/html): ").strip().lower()
        if file_type in ['json', 'csv', 'sql', 'txt', 'md', 'html']:
            return file_type
        else:
            print("Invalid file type. Please enter 'json', 'csv', 'sql', 'txt', 'md', or 'html'.")


def save_data_to_file(data, file_type):
    """Save the generated data to a file of the specified type."""
    if file_type == 'json':
        with open('placeholder_data.json', 'w') as json_file:
            json.dump(data, json_file, indent=4)
    elif file_type == 'csv':
        with open('placeholder_data.csv', 'w', newline='') as csv_file:
            fieldnames = data[0].keys()
            writer = csv.DictWriter(csv_file, fieldnames=fieldnames)
            writer.writeheader()
            for record in data:
                writer.writerow(record)
    elif file_type == 'sql':
        table_name = input("Enter the SQL table name: ")
        columns = input("Enter column names separated by commas: ").split(',')
        sql_statements = generate_sql_insert(table_name, columns, len(data))
        with open('generated_data.sql', 'w') as sql_file:
            sql_file.write('\n'.join(sql_statements))
    elif file_type == 'txt':
        with open('placeholder_data.txt', 'w') as txt_file:
            for record in data:
                txt_file.write(str(record) + '\n')
    elif file_type == 'md':
        with open('placeholder_data.md', 'w') as md_file:
            for record in data:
                md_file.write('- ' + ', '.join([f"{key}: {value}" for key, value in record.items()]) + '\n')
    elif file_type == 'html':
        with open('placeholder_data.html', 'w') as html_file:
            html_file.write('<html>\n<head>\n<title>Placeholder Data</title>\n</head>\n<body>\n')
            for record in data:
                html_file.write('<ul>\n')
                for key, value in record.items():
                    html_file.write(f'<li>{key}: {value}</li>\n')
                html_file.write('</ul>\n')


if __name__ == "__main__":
    num_records = int(input("Enter the number of records to generate: "))
    data_format = get_data_format_from_user()
    file_type = get_file_type_from_user()

    placeholder_data = generate_placeholder_data(num_records, data_format)

    save_data_to_file(placeholder_data, file_type)

    print(f"Data will be saved to: {os.path.abspath('generated_data.sql')}")
