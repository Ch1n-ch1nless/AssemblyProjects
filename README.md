# AssemblyProjects

## Проект: 'PATCH'

## Глава 1. Введение.

Мой дорогой друг  <a href="https://github.com/1progwriter1" target="_blank">Иван</a> скинул мне программу под названием 'PROGRAM.COM', которая находится в папке 'PATCH'. Хотел я её запустить, но, вдруг, программа требует пароль! <br>
Что же делать? Я знаю! Я ВЗЛОМАЮ ПРОГРАММУ!! 👨‍💻👨‍💻

## Глава 2. Первый простой взлом.

Сначала я продизассемблировал программу Вани через <a href="https://hex-rays.com/ida-free/" target="_blank">IDA</a>. Начал разбираться и параллельно покрасил сегменты кода для лучшего понимания и добавил пару комментариев. Мой дизассемблер можно увидеть в 'PATCH/PASSWORD.i64'. Анализируя дальнейший код я заметил следующее: <br>
<img src="/PATCH/images/1.png" width = 50%> <br>
Смотря на желтую линию, можно заметить, что при введении 6 любых символов, а потом нажать 'backspace', то мы получим доступ к паролю! Повторяя данные действия, я получил доступ к программе!!
УРА! 🥳🥳

## Глава 3. Второй, более сложный, взлом.

Анализируя код чтения пароля, я заметил, что там нет ограничения на количество введенных символов! Сейчас будут в картинках показаны куски кода: <br>
<img src="/PATCH/images/2.png" width = 50%> <br>
<img src="/PATCH/images/3.png" width = 50%> <br>
Я попробовал ввести просто 16 символов 'A', но пароль был неправильным. Далее начал анализировать кусок кода, где находилось сравнение паролей: <br>
<img src="/PATCH/images/4.png" width = 50%> <br>
Оказывается Ваня зашифровал свой пароль шифром цезаря, и в переменной byte_128 хранится число 0x0E. Зная, что разница между ASC-II кодами 'A' и 'O' это 14, то тогда я ввел в консоль пароль: "AAAAAAAAOOOOOOOO". И получил доступ к программе! ✅

## Глава 4. Патч.

Постоянно вводить какие-то символы для получения доступа к паролю долго и муторно. Поэтому было решено взломать программу. Анализируя код, я заметил, что по адресу 0x021E хранится начало вывода строки правильного пароля, а по адресу 0x020F неправильного пароля. <br>
<img src="/PATCH/images/5.png" width = 50%> <br>
<img src="/PATCH/images/6.png" width = 50%> <br>
Далее я написал программу на си, которая находит нужный адрес и меняет байт с 0x0F на 0x1E. И чудо! Введя любой символ, я получаю верный доступ!

## Вывод

Решая данную задачу, я получил опыт в дизассемблировании и познакомился с программой <a href="https://hex-rays.com/ida-free/" target="_blank">IDA</a>
