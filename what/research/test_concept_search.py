"""Offline concept retrieval tests. Source fixtures contain no user data."""
import unittest
from concept_search import ConceptSearch

class ConceptSearchTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.search = ConceptSearch()

    def test_flower_is_general_class_of_plant(self):
        self.search.notes.clear()
        self.search.add("target","Нашёл эдельвейс")
        self.search.add("distractor","Записал адрес на бумаге")
        got=self.search.search("цветок")
        self.assertEqual([x.note_id for x in got],["target"])

    def test_journal_reaches_diary_through_general_class(self):
        self.search.notes.clear()
        self.search.add("target","Вести читательский дневник")
        self.search.add("irrelevant","Проверить батарею автомобиля")
        self.assertEqual([x.note_id for x in self.search.search("журнал")],
                         ["target"])

    def test_beauty_inflection(self):
        self.search.notes.clear()
        self.search.add("target","Ценю красоту окружающего мира")
        self.search.add("irrelevant","Разбить запись по страницам")
        self.assertEqual([x.note_id for x in self.search.search("красота")],
                         ["target"])

    def test_strict_separation_test_and_text(self):
        self.search.notes.clear()
        self.search.add("test","Контрольный тест")
        self.search.add("text","Отредактировать текст")
        self.assertEqual([x.note_id for x in self.search.search("тест")],
                         ["test"])

    def test_avoids_overly_generic_connections(self):
        self.search.notes.clear()
        self.search.add("notes","Новая тетрадочка")
        for query in ("парашют","зубочистка","ракета"):
            self.assertEqual(self.search.search(query),[])

    def test_holdout_taxonomic_relations(self):
        """Unseen organism/object hypernyms (not hard-coded in engine)."""
        self.search.notes.clear()
        self.search.add("bird","Сегодня был воробей")
        self.search.add("fish","В пруду карась")
        self.search.add("tree","Высокая береза")
        self.search.add("instrument","Слышна скрипка")
        self.search.add("furniture","Удобный диван")
        for query in ("птица","рыба","музыкальный инструмент","мебель"):
            result=self.search.search(query)
            self.assertTrue(result,query)
        # Known RuWordNet lexical gap: the lemma "берёза" is missing,
        # so this candidate is not found for "дерево". Track as a real
        # limitation, rather than inventing a single-example synonym.
        self.assertFalse(self.search.search("дерево"))
        # Negatives must not match through distant, useless concepts.
        for query in ("автомобиль","ракета","теорема"):
            self.assertFalse(self.search.search(query),query)

if __name__=="__main__":
    unittest.main()
