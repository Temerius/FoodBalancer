import os
import re
import sys

def remove_comments_from_dart_files(folder_path):
    """
    Рекурсивно проходит по всем .dart файлам в указанной папке
    и удаляет комментарии, начинающиеся с //
    """
    # Счетчик обработанных файлов
    processed_files = 0
    
    # Обход всех файлов и папок
    for root, dirs, files in os.walk(folder_path):
        for file in files:
            # Проверяем, что это файл .dart
            if file.endswith(".dart"):
                file_path = os.path.join(root, file)
                
                try:
                    # Читаем содержимое файла
                    with open(file_path, 'r', encoding='utf-8') as f:
                        content = f.read()
                    
                    # Удаляем комментарии (// и всё после них на строке)
                    modified_content = re.sub(r'//.*$', '', content, flags=re.MULTILINE)
                    
                    # Записываем изменённое содержимое обратно
                    with open(file_path, 'w', encoding='utf-8') as f:
                        f.write(modified_content)
                    
                    processed_files += 1
                    print(f"Обработан файл: {file_path}")
                except Exception as e:
                    print(f"Ошибка при обработке файла {file_path}: {e}")
    
    return processed_files

if __name__ == "__main__":
    # Проверка аргументов командной строки
    if len(sys.argv) != 2:
        print("Использование: python script.py <путь_к_папке>")
        sys.exit(1)
    
    folder_path = sys.argv[1]
    
    # Проверка существования папки
    if not os.path.isdir(folder_path):
        print(f"Ошибка: {folder_path} не является папкой")
        sys.exit(1)
    
    # Запуск обработки
    count = remove_comments_from_dart_files(folder_path)
    print(f"Завершено! Обработано файлов: {count}")