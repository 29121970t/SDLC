#include <gtkmm.h>

#include <cmath>
#include <cstdlib>
#include <iomanip>
#include <limits>
#include <optional>
#include <sstream>
#include <string>
#include <algorithm>
#include <vector>

namespace cake_calculator {

constexpr int kCigarettesInPack = 20;
constexpr double kDaysInYear = 365.25;

struct Input {
    int cigarettes_per_day{};
    double pack_price{};
    double tar_mg{};
    double nicotine_mg{};
    int smoking_years{};
    double cake_price{};
    double orange_price{};
};

struct Result {
    double cigarettes{};
    double money_spent{};
    double tar_grams{};
    double nicotine_grams{};
    double cakes{};
    double oranges{};
};

struct State {
    std::optional<Input> input;
    std::optional<Result> result;
};

class IObserver {
public:
    virtual ~IObserver() = default;
    virtual void update(const State& state) = 0;
};

class Subject {
public:
    void attach(IObserver& observer) {
        if (std::find(observers_.begin(), observers_.end(), &observer) == observers_.end())
            observers_.push_back(&observer);
    }

    void detach(IObserver& observer) {
        observers_.erase(std::remove(observers_.begin(), observers_.end(), &observer),
                         observers_.end());
    }

protected:
    void notify(const State& state) const {
        for (IObserver* observer : observers_) observer->update(state);
    }

private:
    std::vector<IObserver*> observers_;
};

class Model : public Subject {
public:
    const State& state() const { return state_; }

    bool calculate(const Input& input, std::string& error) {
        if (!validate(input, error)) return false;

        const double count = static_cast<double>(input.cigarettes_per_day) *
                             kDaysInYear * input.smoking_years;
        Result result;
        result.cigarettes = count;
        result.money_spent = count / kCigarettesInPack * input.pack_price;
        result.tar_grams = count * input.tar_mg / 1000.0;
        result.nicotine_grams = count * input.nicotine_mg / 1000.0;
        result.cakes = result.money_spent / input.cake_price;
        result.oranges = result.money_spent / input.orange_price;

        state_ = {input, result};
        notify(state_);
        return true;
    }

private:
    static bool valid_number(double value) {
        return std::isfinite(value) && value > 0.0;
    }

    static bool validate(const Input& x, std::string& error) {
        if (x.cigarettes_per_day < 1 || x.cigarettes_per_day > 200) {
            error = "Количество сигарет в день должно быть целым числом от 1 до 200.";
        } else if (x.smoking_years < 1 || x.smoking_years > 100) {
            error = "Стаж курения должен быть целым числом от 1 до 100 лет.";
        } else if (!valid_number(x.pack_price) || x.pack_price > 10000) {
            error = "Цена пачки должна быть положительным числом не более 10000 BYN.";
        } else if (!valid_number(x.tar_mg) || x.tar_mg > 100) {
            error = "Содержание смол должно быть положительным числом не более 100 мг.";
        } else if (!valid_number(x.nicotine_mg) || x.nicotine_mg > 100) {
            error = "Содержание никотина должно быть положительным числом не более 100 мг.";
        } else if (!valid_number(x.cake_price) || x.cake_price > 100000) {
            error = "Цена тортика должна быть положительным числом.";
        } else if (!valid_number(x.orange_price) || x.orange_price > 100000) {
            error = "Цена апельсина должна быть положительным числом.";
        } else return true;
        return false;
    }

    State state_;
};

class View;

class Controller {
public:
    explicit Controller(Model& model) : model_(model) {}
    void open_input_dialog(View& view);
    void submit(const std::vector<Glib::ustring>& fields, View& view);

private:
    static bool parse_int(const Glib::ustring& text, int& result);
    static bool parse_double(const Glib::ustring& text, double& result);
    Model& model_;
};

class View : public Gtk::ApplicationWindow, public IObserver {
public:
    explicit View(Controller& controller) : controller_(controller) {
        set_title("Калькулятор тортиков");
        set_default_size(760, 600);
        set_border_width(18);

        title_.set_markup("<span size='x-large' weight='bold'>Калькулятор тортиков</span>");
        subtitle_.set_text("Оценка последствий курения и упущенных покупок");
        subtitle_.get_style_context()->add_class("dim-label");
        enter_button_.set_label("Ввести данные");
        enter_button_.signal_clicked().connect([this] { controller_.open_input_dialog(*this); });

        grid_.set_row_spacing(8);
        grid_.set_column_spacing(18);
        add_row("Выкурено сигарет", cigarettes_);
        add_row("Потрачено на сигареты", money_);
        add_row("Смол прошло через лёгкие", tar_);
        add_row("Никотина прошло через организм", nicotine_);
        add_row("Можно было купить тортиков", cakes_);
        add_row("Можно было купить апельсинов", oranges_);
        clear_result();

        root_.set_spacing(12);
        root_.pack_start(title_, Gtk::PACK_SHRINK);
        root_.pack_start(subtitle_, Gtk::PACK_SHRINK);
        root_.pack_start(separator_, Gtk::PACK_SHRINK);
        root_.pack_start(grid_, Gtk::PACK_EXPAND_WIDGET);
        root_.pack_end(enter_button_, Gtk::PACK_SHRINK);
        add(root_);
        show_all_children();
    }

    void update(const State& state) override {
        if (!state.result) { clear_result(); return; }
        const Result& r = *state.result;
        cigarettes_.set_text(format(r.cigarettes, 0) + " шт.");
        money_.set_text(format(r.money_spent) + " BYN");
        tar_.set_text(format(r.tar_grams) + " г");
        nicotine_.set_text(format(r.nicotine_grams) + " г");
        cakes_.set_text(format(r.cakes, 1) + " шт.");
        oranges_.set_text(format(r.oranges, 1) + " шт.");
    }

    void show_error(const std::string& message) {
        Gtk::MessageDialog dialog(*this, "Некорректные данные", false,
                                  Gtk::MESSAGE_ERROR, Gtk::BUTTONS_OK, true);
        dialog.set_secondary_text(message);
        dialog.run();
    }

private:
    void add_row(const Glib::ustring& caption, Gtk::Label& value) {
        const int row = grid_.get_children().size() / 2;
        auto* label = Gtk::manage(new Gtk::Label(caption, Gtk::ALIGN_START));
        value.set_halign(Gtk::ALIGN_END);
        value.set_selectable(true);
        value.set_markup("<b>—</b>");
        grid_.attach(*label, 0, row, 1, 1);
        grid_.attach(value, 1, row, 1, 1);
    }
    static Glib::ustring format(double value, int precision = 2) {
        std::ostringstream stream;
        stream.imbue(std::locale::classic());
        stream << std::fixed << std::setprecision(precision) << value;
        return stream.str();
    }
    void clear_result() {
        for (auto* label : {&cigarettes_, &money_, &tar_, &nicotine_, &cakes_, &oranges_})
            label->set_text("—");
    }

    Controller& controller_;
    Gtk::Box root_{Gtk::ORIENTATION_VERTICAL};
    Gtk::Label title_, subtitle_;
    Gtk::Separator separator_;
    Gtk::Grid grid_;
    Gtk::Label cigarettes_, money_, tar_, nicotine_, cakes_, oranges_;
    Gtk::Button enter_button_;
};

bool Controller::parse_int(const Glib::ustring& text, int& result) {
    const std::string value = text.raw();
    char* end = nullptr;
    const long number = std::strtol(value.c_str(), &end, 10);
    if (value.empty() || *end != '\0' || number < std::numeric_limits<int>::min() ||
        number > std::numeric_limits<int>::max()) return false;
    result = static_cast<int>(number);
    return true;
}

bool Controller::parse_double(const Glib::ustring& text, double& result) {
    std::string value = text.raw();
    for (char& c : value) if (c == ',') c = '.';
    char* end = nullptr;
    result = std::strtod(value.c_str(), &end);
    return !value.empty() && *end == '\0' && std::isfinite(result);
}

void Controller::open_input_dialog(View& view) {
    Gtk::Dialog dialog("Данные для расчёта", view, true);
    dialog.add_button("Отмена", Gtk::RESPONSE_CANCEL);
    dialog.add_button("Рассчитать", Gtk::RESPONSE_OK);
    Gtk::Grid form;
    form.set_border_width(12);
    form.set_row_spacing(8);
    form.set_column_spacing(12);
    std::vector<Gtk::Entry*> entries;
    const std::vector<Glib::ustring> labels = {
        "Сигарет в день", "Цена пачки, BYN", "Смолы в сигарете, мг",
        "Никотина в сигарете, мг", "Стаж курения, лет", "Цена тортика, BYN",
        "Цена апельсина, BYN"};
    const std::vector<Glib::ustring> defaults = {"10", "5.50", "6", "0.5", "5", "25", "1.50"};
    for (std::size_t i = 0; i < labels.size(); ++i) {
        auto* entry = Gtk::manage(new Gtk::Entry());
        entry->set_width_chars(15);
        entry->set_placeholder_text(defaults[i]);
        form.attach(*Gtk::manage(new Gtk::Label(labels[i], Gtk::ALIGN_START)), 0, i, 1, 1);
        form.attach(*entry, 1, i, 1, 1);
        entries.push_back(entry);
    }
    if (model_.state().input) {
        const Input& x = *model_.state().input;
        const std::vector<Glib::ustring> values = {std::to_string(x.cigarettes_per_day),
            std::to_string(x.pack_price), std::to_string(x.tar_mg), std::to_string(x.nicotine_mg),
            std::to_string(x.smoking_years), std::to_string(x.cake_price), std::to_string(x.orange_price)};
        for (std::size_t i = 0; i < entries.size(); ++i) entries[i]->set_text(values[i]);
    }
    dialog.get_content_area()->pack_start(form);
    dialog.show_all_children();
    if (dialog.run() == Gtk::RESPONSE_OK) {
        std::vector<Glib::ustring> fields;
        for (auto* entry : entries) fields.push_back(entry->get_text());
        submit(fields, view);
    }
}

void Controller::submit(const std::vector<Glib::ustring>& fields, View& view) {
    Input input;
    if (fields.size() != 7 || !parse_int(fields[0], input.cigarettes_per_day) ||
        !parse_double(fields[1], input.pack_price) || !parse_double(fields[2], input.tar_mg) ||
        !parse_double(fields[3], input.nicotine_mg) || !parse_int(fields[4], input.smoking_years) ||
        !parse_double(fields[5], input.cake_price) || !parse_double(fields[6], input.orange_price)) {
        view.show_error("Заполните все поля числами. Для дробной части допустимы точка или запятая.");
        return;
    }
    std::string error;
    if (!model_.calculate(input, error)) view.show_error(error);
}

} // namespace cake_calculator

int main(int argc, char* argv[]) {
    auto app = Gtk::Application::create(argc, argv, "by.bsuir.sdlc.cake-calculator");
    cake_calculator::Model model;
    cake_calculator::Controller controller(model);
    cake_calculator::View view(controller);
    model.attach(view);
    return app->run(view);
}
