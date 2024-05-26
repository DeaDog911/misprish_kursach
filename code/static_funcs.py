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
            return "классификация"
        case "product":
            return "продукт"
        case "parameter":
            return "параметры"
        case "unit":
            return "единицы измерения"
        case "par_class":
            return "классификация параметров"
        case "par_prod":
            return "продуктовые параметры"
        case "pos_agr":
            return "агрегация позиций"
        case "pos_enum":
            return "позиционные перечисления"
        case _:
            return english_name  # Если название не найдено, возвращаем английское название
