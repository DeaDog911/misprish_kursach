def get_russian_table_name(english_name: str) -> str:
    """
    Получает русское название таблицы по английскому названию.

    Параметры:
    - english_name (str): Английское название таблицы.

    Возвращает:
    str: Русское название таблицы или английское название, если соответствие не найдено.
    """
    match english_name:
        case "classification":
            return "Классификация"
        case "product":
            return "Изделие"
        case "unit":
            return "Единицы измерения"
        case "spec_position":
            return "Спецификация"
        case _:
            return english_name  # Если название не найдено, возвращаем английское название
