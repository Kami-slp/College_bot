import telebot
from Only_functions import *
from telebot import types
import os
import uuid


API_TOKEN = '8482314356:AAHFdI_aofVg9EAVn1YU8g3YPHz8d-ItQeQ'
bot = telebot.TeleBot(API_TOKEN)






user_state = {}



def main_menu():
    markup = types.ReplyKeyboardMarkup(resize_keyboard=True)
    markup.row('Домашние задания', 'Посещаемость преподавателей')
    markup.row('Проверка домашних заданий', 'Темы уроков')
    markup.row('Расписание группы')
    return markup



@bot.message_handler(commands=['start'])
def start(message):
    bot.send_message(message.chat.id, "Привет! Выбери какой отчет сделать:", reply_markup=main_menu())



@bot.message_handler(func=lambda message: True)
def choose_report(message):
    if message.text in ['Домашние задания', 'Посещаемость преподавателей',
                        'Проверка домашних заданий', 'Темы уроков', 'Расписание группы']:
        user_state[message.chat.id] = message.text
        bot.send_message(message.chat.id, f"Вы выбрали: {message.text}. Отправьте Excel файл.")
    else:

        if message.chat.id in user_state:
            bot.send_message(message.chat.id, "Пожалуйста, отправьте файл, а не текст.")
        else:
            bot.send_message(message.chat.id, "Нажмите на кнопку, чтобы выбрать отчет.", reply_markup=main_menu())



@bot.message_handler(content_types=['document'])
def handle_file(message):
    chat_id = message.chat.id

    if chat_id not in user_state:
        bot.send_message(chat_id, "Сначала выберите отчет из меню.", reply_markup=main_menu())
        return

    file_info = bot.get_file(message.document.file_id)
    downloaded_file = bot.download_file(file_info.file_path)


    file_extension = os.path.splitext(message.document.file_name)[1]
    unique_filename = f"{uuid.uuid4()}{file_extension}"
    file_path = f"./{unique_filename}"
    
    with open(file_path, 'wb') as f:
        f.write(downloaded_file)

    bot.send_message(chat_id, "Файл получен! Обрабатываю...")

    report_type = user_state[chat_id]
    try:
        if report_type == 'Расписание группы':
            df_result = Show_Amount_of_doppelstunden_ja_das_ist_Deutch(file_path)
        elif report_type == 'Темы уроков':
            df_result = Filter_topics_name(file_path)
        elif report_type == 'Проверка домашних заданий':
            df_result = Filter_HomeworkChecked_percentage(file_path)
        elif report_type == 'Посещаемость преподавателей':
            df_result = Filter_Teacher_Attendance(file_path)
        elif report_type == 'Домашние задания':
            df_result = filter_homework_percentage(file_path)


        result_filename = f"result_{uuid.uuid4()}.xlsx"
        result_filepath = f"./{result_filename}"
        df_result.to_excel(result_filepath, index=False)
        
        with open(result_filepath, 'rb') as result_file:
            bot.send_document(chat_id, result_file, caption="Результат обработки")
        

        if os.path.exists(result_filepath):
            os.remove(result_filepath)

    except Exception as e:
        bot.send_message(chat_id, f"Ошибка при обработке файла: {e}")
    finally:

        if os.path.exists(file_path):
            try:
                os.remove(file_path)
            except Exception as e:
                print(f"Не удалось удалить файл {file_path}: {e}")

    user_state.pop(chat_id)


bot.polling(none_stop=True)