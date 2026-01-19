import pandas as pd
import re
from collections import Counter
pd.set_option('display.max_colwidth', None)
pd.set_option('display.max_columns', None)
pd.set_option('display.max_rows', None)

def filter_homework_percentage(file_path):


    df = pd.read_excel(file_path)

    df['Percentage Homework'] = pd.to_numeric(
        df['Percentage Homework'],
        errors='coerce'
    )

    filtered = df[df['Percentage Homework'] < 70]

    return filtered[['FIO', 'Percentage Homework']]
def filter_homework_classwork(file_path):
    df = pd.read_excel(file_path)

    df['Homework'] = pd.to_numeric(
        df['Homework'],
        errors='coerce'
    )

    df['Classroom'] = pd.to_numeric(
        df['Classroom'],
        errors='coerce'
    )

    filtered = df[
        (df['Homework'] <= 1) &
        (df['Classroom'] <= 3)
        ]

    return filtered[['FIO', 'Homework','Classroom']]




def Filter_Teacher_Attendance(file_path):
    df = pd.read_excel(file_path)
    df.columns = df.columns.str.strip()
    df['Средняя посещаемость'] = df['Средняя посещаемость'].str.rstrip('%').astype(float)
    filtered = df[df['Средняя посещаемость']< 40]
    return filtered[['ФИО преподавателя', 'Средняя посещаемость']]


def Filter_HomeworkChecked_percentage(file_path):
    df = pd.read_excel(file_path, header=[0, 1])
    df.columns = [' '.join(col).strip() if isinstance(col, tuple) else col for col in df.columns]

    df['Месяц Проверено'] = df['Месяц Проверено'].fillna(0)
    df['Месяц Получено'] = df['Месяц Получено'].fillna(0).replace(0, 1)

    df['Неделя Проверено'] = df['Неделя Проверено'].fillna(0)
    df['Неделя Получено'] = df['Неделя Получено'].fillna(0).replace(0, 1)

    df['Процент_месяц'] = df['Месяц Проверено'] / df['Месяц Получено'] * 100
    df['Процент_неделя'] = df['Неделя Проверено'] / df['Неделя Получено'] * 100

    filtered = df[(df['Процент_месяц'] < 70) & (df['Процент_неделя'] < 70)]


    return filtered[['ФИО преподавателя Unnamed: 1_level_1', 'Процент_месяц', 'Процент_неделя']]



def Filter_topics_name(file_path):
    df = pd.read_excel(file_path)
    pattern = r'^Урок №\d+\. Тема: .+'

    filtered = df[~df['Тема урока'].astype(str).str.match(pattern)]

    return filtered[['Предмет','Тема урока']]



def Show_Amount_of_doppelstunden_ja_das_ist_Deutch(file_path):
    df = pd.read_excel(file_path)
    records = []

    for col in df.columns:
        if col not in ['Группа', 'Пара', 'Время']:
            for idx, val in df[col].dropna().items():
                match = re.search(r'Предмет:\s*(.+)', str(val))
                if match:
                    subject = match.group(1).strip()
                    group = df.loc[idx, 'Группа']
                    records.append((group, subject))

    counter = Counter(records)
    result = pd.DataFrame(
        [(g, s, c) for (g, s), c in counter.items()],
        columns=['Группа', 'Предмет', 'Количество пар']
    )
    return result

