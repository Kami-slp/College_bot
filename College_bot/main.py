import telebot
from Only_functions import *
from telebot import types
from io import BytesIO

API_TOKEN = '8150565426:AAFVcl9ULFaz3BTVf5hDm9jSh4cLeiRt8SU'
bot = telebot.TeleBot(API_TOKEN)

user_state = {}


def format_dataframe_preview(df, max_rows=5):

    preview_df = df.head(max_rows)
    

    col_widths = {}
    for col in preview_df.columns:
        col_widths[col] = max(
            len(str(col)),
            preview_df[col].astype(str).str.len().max() if len(preview_df) > 0 else 0
        )
    

    lines = []
    

    header_parts = [str(col).ljust(col_widths[col]) for col in preview_df.columns]
    lines.append(" | ".join(header_parts))
    

    for idx, row in preview_df.iterrows():
        row_parts = [str(row[col]).ljust(col_widths[col]) for col in preview_df.columns]
        lines.append(" | ".join(row_parts))
    
    return "\n".join(lines)


def main_menu():
    markup = types.ReplyKeyboardMarkup(resize_keyboard=True)
    markup.row('📚 Домашние задания', '🧑‍🏫 Посещаемость преподавателей')
    markup.row('✅ Проверка ДЗ', '📝 Темы уроков')
    markup.row('📅 Расписание группы','👨‍🎓 Отчет по студентам')
    return markup



@bot.message_handler(commands=['start'])
def start(message):
    bot.send_message(
        message.chat.id,
        "👋 Привет! Я бот для отчетов по учебной деятельности.\n"
        "Выбери какой отчет сделать:",
        reply_markup=main_menu()
    )



@bot.message_handler(func=lambda message: True)
def choose_report(message):
    options = [
        '📚 Домашние задания',
        '🧑‍🏫 Посещаемость преподавателей',
        '✅ Проверка ДЗ',
        '📝 Темы уроков',
        '📅 Расписание группы',
        '👨‍🎓 Отчет по студентам'
    ]

    if message.text in options:
        user_state[message.chat.id] = message.text

        descriptions = {
            '📅 Расписание группы': "📊 Отчет по выставленному расписанию. Подгрузи файл с расписанием группы на неделю, и я покажу количество пар по каждой дисциплине.",
            '📝 Темы уроков': "📝 Отчет по темам занятия. Подгрузи файл с темами уроков. Я покажу все темы, которые не соответствуют формату 'Урок № _. Тема: _'.",
            '✅ Проверка ДЗ': "✅ Отчет по проверенным домашним заданиям. Я покажу преподавателей, чей процент проверяемых заданий ниже 70% за месяц и неделю.",
            '🧑‍🏫 Посещаемость преподавателей': "📉 Отчет по посещаемости студентов. Я покажу преподавателей с посещаемостью пар ниже 40%.",
            '📚 Домашние задания': "📌 Отчет по сданным домашним заданиям. Я покажу студентов, у которых % выполненных заданий ниже 70%.",
            '👨‍🎓 Отчет по студентам': (
                "👨‍🎓 Отчет по студентам.\n"
                "Будут показаны студенты, у которых:\n"
                "• средняя оценка за ДЗ = 1\n"
                "• оценка за классную работу ≤ 3"
            )
        }
        bot.send_message(message.chat.id,
                         f"Вы выбрали: {message.text}\n{descriptions[message.text]}\n\n📎 Отправьте Excel файл для обработки.")
    else:
        if message.chat.id in user_state:
            bot.send_message(message.chat.id, "⚠️ Пожалуйста, отправьте файл, а не текст.")
        else:
            bot.send_message(message.chat.id, "❗ Нажмите на кнопку, чтобы выбрать отчет.", reply_markup=main_menu())



@bot.message_handler(content_types=['document'])
def handle_file(message):
    chat_id = message.chat.id

    if chat_id not in user_state:
        bot.send_message(chat_id, "⚠️ Сначала выберите отчет из меню.", reply_markup=main_menu())
        return


    file_info = bot.get_file(message.document.file_id)
    downloaded_file = bot.download_file(file_info.file_path)
    file_bytes = BytesIO(downloaded_file)

    bot.send_message(chat_id, "⏳ Файл получен! Обрабатываю...")

    report_type = user_state[chat_id]
    try:

        if report_type == '📅 Расписание группы':
            df_result = Show_Amount_of_doppelstunden_ja_das_ist_Deutch(file_bytes)
        elif report_type == '📝 Темы уроков':
            df_result = Filter_topics_name(file_bytes)
        elif report_type == '✅ Проверка ДЗ':
            df_result = Filter_HomeworkChecked_percentage(file_bytes)
        elif report_type == '🧑‍🏫 Посещаемость преподавателей':
            df_result = Filter_Teacher_Attendance(file_bytes)
        elif report_type == '📚 Домашние задания':
            df_result = filter_homework_percentage(file_bytes)
        elif report_type == '👨‍🎓 Отчет по студентам':
            df_result = filter_homework_classwork(file_bytes)






        preview_rows = 5
        formatted_preview = format_dataframe_preview(df_result, max_rows=preview_rows)
        
        preview_text = f"📊 Превью результата (первые {min(preview_rows, len(df_result))} строк из {len(df_result)}):\n\n"
        preview_text += formatted_preview
        
        if len(df_result) > preview_rows:
            preview_text += f"\n\n... и еще {len(df_result) - preview_rows} строк(и) в файле"
        
        
        if len(preview_text) > 4000:
            preview_text = preview_text[:4000] + "\n\n(текст обрезан, полные данные в файле)"
        
        bot.send_message(chat_id, preview_text)
        
        result_bytes = BytesIO()
        df_result.to_excel(result_bytes, index=False)
        result_bytes.seek(0)


        bot.send_document(chat_id, ('result.xlsx', result_bytes), caption="📄 Результат обработки")

        bot.send_message(chat_id, "✅ Готово! Можете отправить следующий файл или выбрать другой отчет.",
                         reply_markup=main_menu())

    except Exception as e:
        bot.send_message(chat_id, f"❌ Ошибка при обработке файла: {e}")


    user_state.pop(chat_id)



bot.polling(none_stop=True)
