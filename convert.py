import csv
import os

def convert_dat_to_csv(dat_file, csv_file, headers):
    print(f"Конвертація {dat_file} -> {csv_file}...")
    # Читаємо з кодуванням latin-1, як вказано в завданні
    with open(dat_file, 'r', encoding='latin-1') as f_in, \
         open(csv_file, 'w', encoding='utf-8', newline='') as f_out:
        
        writer = csv.writer(f_out)
        writer.writerow(headers) # Записуємо заголовки колонок
        
        for line in f_in:
            # Видаляємо зайві пробіли/перенесення і розбиваємо рядок по '::'
            row = line.strip().split('::')
            writer.writerow(row)

# Перевіряємо, чи існує папка import, якщо ні - створюємо
os.makedirs('import', exist_ok=True)

# Визначаємо заголовки для кожного файлу згідно з документацією MovieLens
movies_headers = ['MovieID', 'Title', 'Genres']
users_headers = ['UserID', 'Gender', 'Age', 'Occupation', 'ZipCode']
ratings_headers = ['UserID', 'MovieID', 'Rating', 'Timestamp']

# Запускаємо конвертацію
convert_dat_to_csv('import/ml-1m/movies.dat', 'import/movies.csv', movies_headers)
convert_dat_to_csv('import/ml-1m/users.dat', 'import/users.csv', users_headers)
convert_dat_to_csv('import/ml-1m/ratings.dat', 'import/ratings.csv', ratings_headers)

print("✅ Конвертація успішно завершена! Файли збережено у папці import/")