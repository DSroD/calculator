/*-
 * Copyright 2018-2019 elementary, Inc. (https://elementary.io)
 *           2014 Marvin Beckers <beckersmarvin@gmail.com>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Authored by: Marvin Beckers <beckersmarvin@gmail.com>
 */

namespace PantheonCalculator {
    public class MainWindow : Hdy.ApplicationWindow {
        private uint configure_id;
        private static GLib.Settings settings;

        private Gtk.Revealer extended_revealer;
        private Gtk.Entry entry;
        private Gtk.Image extended_img_1;
        private Gtk.Image extended_img_2;
        private Gtk.Button button_calc;
        private Gtk.Button button_history;
        private Gtk.Button button_ans;
        private Gtk.Button button_del;
        private Gtk.Button button_mr;
        private Gtk.Button button_mc;
        private Gtk.Button button_gt;
        private Gtk.ToggleButton button_extended;
        private HistoryDialog history_dialog;

        private Gtk.InfoBar infobar;
        private Gtk.Label infobar_label;

        private Core.Evaluation eval;

        private List<History?> history;
        private int position;

        /* Define the decimal places */
        private int decimal_places;

        public struct History { string exp; string output; }
        private double memory_value = 0;

        public const string ACTION_PREFIX = "win.";
        public const string ACTION_CLEAR = "action-clear";

        private const ActionEntry[] ACTION_ENTRIES = {
            { ACTION_CLEAR, action_clear }
        };

        static construct {
            settings = new Settings ("io.elementary.calculator.saved-state");
        }

        construct {
            Hdy.init ();
            add_action_entries (ACTION_ENTRIES, this);

            var application_instance = (Gtk.Application) GLib.Application.get_default ();
            application_instance.set_accels_for_action (ACTION_PREFIX + ACTION_CLEAR, {"Escape"});

            set_resizable (false);
            window_position = Gtk.WindowPosition.CENTER;

            decimal_places = settings.get_int ("decimal-places");

            eval = new Core.Evaluation ();

            history = new List<History?> ();
            position = 0;

            int window_x, window_y;
            settings.get ("window-position", "(ii)", out window_x, out window_y);

            if (window_x != -1 || window_y != -1) {
                move (window_x, window_y);
            }

            extended_img_1 = new Gtk.Image.from_icon_name ("pane-hide-symbolic", Gtk.IconSize.MENU);
            extended_img_2 = new Gtk.Image.from_icon_name ("pane-show-symbolic", Gtk.IconSize.MENU);

            button_extended = new Gtk.ToggleButton () {
                image = extended_img_1,
                tooltip_text = _("Show extended functionality")
            };
            button_extended.toggled.connect (toggle_grid);

            button_history = new Gtk.Button () {
                image = new Gtk.Image.from_icon_name ("document-open-recent-symbolic", Gtk.IconSize.MENU),
                tooltip_text = _("History"),
                sensitive = false
            };
            button_history.clicked.connect (show_history);

            var headerbar = new Hdy.HeaderBar () {
                has_subtitle = false,
                show_close_button = true,
                title = _("Calculator")
            };
            headerbar.pack_end (button_extended);
            headerbar.pack_end (button_history);
            headerbar.get_style_context ().add_class ("default-decoration");

            entry = new Gtk.Entry () {
                xalign = 1,
                vexpand = true,
                valign = Gtk.Align.FILL
            };
            entry.get_style_context ().add_class (Granite.STYLE_CLASS_H2_LABEL);

            button_calc = new Button ("=", _("Calculate Result"));
            button_calc.get_style_context ().add_class (Granite.STYLE_CLASS_H2_LABEL);
            button_calc.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);

            button_ans = new Button ("ANS", _("Insert last result"));
            button_ans.sensitive = false;

            button_del = new Button ("Del", _("Backspace"));

            var button_clr = new Button ("C");
            button_clr.action_name = ACTION_PREFIX + ACTION_CLEAR;
            button_clr.tooltip_markup = Granite.markup_accel_tooltip (
                application_instance.get_accels_for_action (button_clr.action_name),
                _("Clear entry")
            );
            button_clr.get_style_context ().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);

            var button_add = new Button (" + ", _("Add"));
            button_add.function = "+";
            button_add.get_style_context ().add_class (Granite.STYLE_CLASS_H3_LABEL);

            var button_sub = new Button (" − ", _("Subtract"));
            button_sub.function = "−";
            button_sub.get_style_context ().add_class (Granite.STYLE_CLASS_H3_LABEL);

            var button_mult = new Button (" × ", _("Multiply"));
            button_mult.function = "×";
            button_mult.get_style_context ().add_class (Granite.STYLE_CLASS_H3_LABEL);

            var button_div = new Button (" ÷ ", _("Divide"));
            button_div.function = "÷";
            button_div.get_style_context ().add_class (Granite.STYLE_CLASS_H3_LABEL);

            var button_0 = new Button ("0");
            var button_point = new Button (Posix.nl_langinfo (Posix.NLItem.RADIXCHAR));
            var button_percent = new Button ("%", _("Percentage"));
            var button_1 = new Button ("1");
            var button_2 = new Button ("2");
            var button_3 = new Button ("3");

            var button_4 = new Button ("4");
            var button_5 = new Button ("5");
            var button_6 = new Button ("6");

            var button_7 = new Button ("7");
            var button_8 = new Button ("8");
            var button_9 = new Button ("9");

            var basic_grid = new Gtk.Grid () {
                column_spacing = 6,
                row_spacing = 6,
                row_spacing = 6,
                row_homogeneous = true
            };

            basic_grid.attach (entry, 0, 0, 4, 1);
            basic_grid.attach (button_clr, 0, 1, 1, 1);
            basic_grid.attach (button_del, 1, 1, 1, 1);
            basic_grid.attach (button_percent, 2, 1, 1, 1);
            basic_grid.attach (button_div, 3, 1, 1, 1);

            basic_grid.attach (button_7, 0, 2, 1, 1);
            basic_grid.attach (button_8, 1, 2, 1, 1);
            basic_grid.attach (button_9, 2, 2, 1, 1);
            basic_grid.attach (button_mult, 3, 2, 1, 1);

            basic_grid.attach (button_4, 0, 3, 1, 1);
            basic_grid.attach (button_5, 1, 3, 1, 1);
            basic_grid.attach (button_6, 2, 3, 1, 1);
            basic_grid.attach (button_sub, 3, 3, 1, 1);

            basic_grid.attach (button_1, 0, 4, 1, 1);
            basic_grid.attach (button_2, 1, 4, 1, 1);
            basic_grid.attach (button_3, 2, 4, 1, 1);
            basic_grid.attach (button_add, 3, 4, 1, 1);

            basic_grid.attach (button_0, 0, 5, 1, 1);
            basic_grid.attach (button_point, 1, 5, 1, 1);
            basic_grid.attach (button_ans, 2, 5, 1, 1);
            basic_grid.attach (button_calc, 3, 5, 1, 1);

            var button_ms = new Button ("MS", _("Set memory value"));
            button_mr = new Button ("MR", _("Recall value from memory"));
            button_mr.set_sensitive (false);
            var button_m_add = new Button ("M+", _("Add to stored value"));
            var button_m_sub = new Button ("M−", _("Subtract from stored value"));
            button_mc = new Button ("MC", _("Clear memory"));
            button_mc.set_sensitive (false);
            button_gt = new Button ("GT", _("Grand Total"));
            button_gt.set_sensitive (false);
            var button_par_left = new Button ("(", _("Start Group"));
            var button_par_right = new Button (")", _("End Group"));
            var button_pow = new Button ("x<sup>y</sup>", _("Exponent"));
            button_pow.function = "^";
            var button_sr = new Button ("√", _("Root"));
            var button_sin = new Button ("sin", _("Sine"));
            var button_sinh = new Button ("sinh", _("Hyperbolic Sine"));
            var button_cos = new Button ("cos", _("Cosine"));
            var button_cosh = new Button ("cosh", _("Hyperbolic Cosine"));
            var button_tan = new Button ("tan", _("Tangent"));
            var button_tanh = new Button ("tanh", _("Hyperbolic Tangent"));
            var button_pi = new Button ("π", _("Pi"));
            var button_e = new Button ("e", _("Euler's Number"));
            var button_log = new Button ("log<sub>10</sub>", _("Logarithm Base 10"));
            button_log.function = "log";
            var button_ln = new Button ("ln", _("Natural Logarithm"));
            var button_asin = new Button ("sin<sup>-1</sup>", _("Inverse Sine"));
            button_asin.function = "asin";
            var button_acos = new Button ("cos<sup>-1</sup>", _("Inverse Cosine"));
            button_acos.function = "acos";
            var button_atan = new Button ("tan<sup>-1</sup>", _("Inverse Tangent"));
            button_atan.function = "atan";
            var button_reciprocal = new Button ("x<sup>-1</sup>", _("Reciprocal"));

            var extended_grid = new Gtk.Grid () {
                margin_start = 6,
                column_spacing = 6,
                row_spacing = 6,
                valign = Gtk.Align.FILL,
                row_homogeneous = true
            };

            // First row
            extended_grid.attach (button_ms, 0, 0, 1, 1);
            extended_grid.attach (button_par_left, 1, 0, 1, 1);
            extended_grid.attach (button_par_right, 2, 0, 1, 1);
            extended_grid.attach (button_log, 3, 0, 1, 1);
            // Second row
            extended_grid.attach (button_mr, 0, 1, 1, 1);
            extended_grid.attach (button_pow, 1, 1, 1, 1);
            extended_grid.attach (button_sr, 2, 1, 1, 1);
            extended_grid.attach (button_ln, 3, 1, 1, 1);
            // Third row
            extended_grid.attach (button_m_add, 0, 2, 1, 1);
            extended_grid.attach (button_sin, 1, 2, 1, 1);
            extended_grid.attach (button_sinh, 2, 2, 1, 1);
            extended_grid.attach (button_asin, 3, 2, 1, 1);
            // Fourth row
            extended_grid.attach (button_m_sub, 0, 3, 1, 1);
            extended_grid.attach (button_cos, 1, 3, 1, 1);
            extended_grid.attach (button_cosh, 2, 3, 1, 1);
            extended_grid.attach (button_acos, 3, 3, 1, 1);
            // Fifth row
            extended_grid.attach (button_mc, 0, 4, 1, 1);
            extended_grid.attach (button_tan, 1, 4, 1, 1);
            extended_grid.attach (button_tanh, 2, 4, 1, 1);
            extended_grid.attach (button_atan, 3, 4, 1, 1);
            // Sixth row
            extended_grid.attach (button_gt, 0, 5, 1, 1);
            extended_grid.attach (button_pi, 1, 5, 1, 1);
            extended_grid.attach (button_e, 2, 5, 1, 1);
            extended_grid.attach (button_reciprocal, 3, 5, 1, 1);

            extended_revealer = new Gtk.Revealer ();
            extended_revealer.set_transition_type (Gtk.RevealerTransitionType.SLIDE_LEFT);
            extended_revealer.show_all ();
            extended_revealer.add (extended_grid);

            var main_grid = new Gtk.Grid ();
            main_grid.margin = 6;
            main_grid.add (basic_grid);
            main_grid.add (extended_revealer);

            infobar_label = new Gtk.Label ("");

            infobar = new Gtk.InfoBar () {
                message_type = Gtk.MessageType.WARNING,
                revealed = false,
                show_close_button = false
            };
            infobar.get_content_area ().add (infobar_label);

            var global_grid = new Gtk.Grid ();
            global_grid.orientation = Gtk.Orientation.VERTICAL;
            global_grid.add (headerbar);
            global_grid.add (infobar);
            global_grid.add (main_grid);

            add (global_grid);

            var granite_settings = Granite.Settings.get_default ();
            var gtk_settings = Gtk.Settings.get_default ();

            gtk_settings.gtk_application_prefer_dark_theme = (
                granite_settings.prefers_color_scheme == Granite.Settings.ColorScheme.DARK
            );

            granite_settings.notify["prefers-color-scheme"].connect (() => {
                gtk_settings.gtk_application_prefer_dark_theme = (
                    granite_settings.prefers_color_scheme == Granite.Settings.ColorScheme.DARK
                );
            });

            show_all ();

            this.key_press_event.connect (key_pressed);

            entry.changed.connect (remove_error);
            entry.activate.connect (button_calc_clicked);

            button_calc.clicked.connect (() => {button_calc_clicked ();});
            button_del.clicked.connect (() => {button_del_clicked ();});
            button_ans.clicked.connect (() => {button_ans_clicked ();});
            button_add.clicked.connect (() => {regular_button_clicked (button_add.function);});
            button_sub.clicked.connect (() => {regular_button_clicked (button_sub.function);});
            button_mult.clicked.connect (() => {regular_button_clicked (button_mult.function);});
            button_div.clicked.connect (() => {regular_button_clicked (button_div.function);});
            button_0.clicked.connect (() => {regular_button_clicked (button_0.function);});
            button_1.clicked.connect (() => {regular_button_clicked (button_1.function);});
            button_2.clicked.connect (() => {regular_button_clicked (button_2.function);});
            button_3.clicked.connect (() => {regular_button_clicked (button_3.function);});
            button_4.clicked.connect (() => {regular_button_clicked (button_4.function);});
            button_5.clicked.connect (() => {regular_button_clicked (button_5.function);});
            button_6.clicked.connect (() => {regular_button_clicked (button_6.function);});
            button_7.clicked.connect (() => {regular_button_clicked (button_7.function);});
            button_8.clicked.connect (() => {regular_button_clicked (button_8.function);});
            button_9.clicked.connect (() => {regular_button_clicked (button_9.function);});
            button_point.clicked.connect (() => {regular_button_clicked (button_point.function);});
            button_percent.clicked.connect (() => {regular_button_clicked (button_percent.function);});

            button_ms.clicked.connect (() => {button_memory_store_clicked ();});
            button_par_left.clicked.connect (() => {regular_button_clicked (button_par_left.function);});
            button_par_right.clicked.connect (() => {regular_button_clicked (button_par_right.function);});
            button_log.clicked.connect (() => {function_button_clicked (button_log.function);});
            button_mr.clicked.connect (() => {regular_button_clicked (number_to_string (memory_value));});
            button_pow.clicked.connect (() => {regular_button_clicked (button_pow.function);});
            button_sr.clicked.connect (() => {function_button_clicked (button_sr.function);});
            button_ln.clicked.connect (() => {function_button_clicked (button_ln.function);});
            button_m_add.clicked.connect (() => {button_memory_add_clicked ();});
            button_sin.clicked.connect (() => {function_button_clicked (button_sin.function);});
            button_sinh.clicked.connect (() => {function_button_clicked (button_sinh.function);});
            button_asin.clicked.connect (() => {function_button_clicked (button_asin.function);});
            button_m_sub.clicked.connect (() => {button_memory_subtract_clicked ();});
            button_cos.clicked.connect (() => {function_button_clicked (button_cos.function);});
            button_cosh.clicked.connect (() => {function_button_clicked (button_cosh.function);});
            button_acos.clicked.connect (() => {function_button_clicked (button_acos.function);});
            button_mc.clicked.connect (() => {button_memory_clear_clicked ();});
            button_tan.clicked.connect (() => {function_button_clicked (button_tan.function);});
            button_tanh.clicked.connect (() => {function_button_clicked (button_tanh.function);});
            button_atan.clicked.connect (() => {function_button_clicked (button_atan.function);});
            button_gt.clicked.connect (() => {button_gt_clicked ();});
            button_pi.clicked.connect (() => {regular_button_clicked (button_pi.function);});
            button_e.clicked.connect (() => {regular_button_clicked (button_e.function);});
            button_reciprocal.clicked.connect (() => {button_reciprocal_clicked ();});

            settings.bind ("extended-shown", button_extended, "active", GLib.SettingsBindFlags.DEFAULT | SettingsBindFlags.GET_NO_CHANGES);

            // The window is constructed before adding to the application.
            // So for the first window, the application will have 0 windows
            if (application_instance.get_windows ().length () == 0) {
                //Only remember the contents of the entry in the first window (subject to privacy settings)
                var privacy_settings = new Settings ("org.gnome.desktop.privacy");
                if (privacy_settings.get_boolean ("remember-recent-files")) {
                    settings.bind ("entry-content", entry, "text", GLib.SettingsBindFlags.DEFAULT);
                }
            }
        }

        public void undo () {
            unowned List<History?> previous_entry = history.last ();
            if (previous_entry != null) {
                entry.set_text (previous_entry.data.exp);
                history.remove_link (previous_entry);
            }
        }

        private void regular_button_clicked (string label) {
            int new_position = entry.get_position ();
            int selection_start, selection_end, selection_length;
            bool is_text_selected = entry.get_selection_bounds (out selection_start, out selection_end);
            if (is_text_selected) {
                new_position = selection_end;
                entry.delete_selection ();
                selection_length = selection_end - selection_start;
                new_position -= selection_length;
            }
            entry.insert_at_cursor (label);
            new_position += label.char_count ();
            entry.grab_focus ();
            entry.set_position (new_position);
        }

        private void function_button_clicked (string label) {
            int selection_start = -1;
            int selection_end = -1;
            if (entry.get_selection_bounds (out selection_start, out selection_end)) {
                int new_position = selection_start;
                string selected_text = entry.get_chars (selection_start, selection_end);
                string function_call = label + "(" + selected_text + ")";
                entry.delete_text (selection_start, selection_end);
                entry.insert_text (function_call, -1, ref selection_start);
                new_position += function_call.char_count ();
                entry.grab_focus ();
                entry.set_position (new_position);
            } else {
                regular_button_clicked (label);
            }
        }

        private void button_calc_clicked () {
            position = entry.get_position ();
            if (entry.get_text () != "") {
                try {
                    var output = eval.evaluate (entry.get_text (), decimal_places);
                    if (entry.get_text () != output) {
                        History history_entry = History () { exp = entry.get_text (), output = output };
                        history.append (history_entry);
                        update_history_dialog (history_entry);
                        entry.set_text (output);
                        button_history.set_sensitive (true);
                        button_ans.set_sensitive (true);
                        button_gt.set_sensitive (true);

                        position = output.length;
                        remove_error ();
                    }
                } catch (Core.OUT_ERROR e) {
                    infobar_label.label = e.message;
                    infobar.revealed = true;
                }
            } else {
                remove_error ();
            }

            entry.grab_focus ();
            entry.set_position (position);
        }

        private void button_reciprocal_clicked () {
            entry.set_text ("1/(" + entry.get_text () + ")");
            button_calc_clicked ();
        }

        private void button_del_clicked () {
            position = entry.get_position ();
            if (entry.get_text ().length > 0) {
                string new_text = "";
                int index = 0;
                unowned unichar c;
                List<unichar> news = new List<unichar> ();

                for (int i = 0; entry.get_text ().get_next_char (ref index, out c); i++) {
                    if (i + 1 != position) {
                        news.append (c);
                    }
                }

                foreach (unichar u in news) {
                    new_text += u.to_string ();
                }

                entry.set_text (new_text);
            }

            entry.grab_focus ();
            entry.set_position (position - 1);
        }

        private void button_memory_store_clicked () {
            if (entry.get_text () != "") {
                try {
                    /* This is necessary because we don't want to accept non-numeric values.
                     * Moreover, it allows the saving in memory of the result of complex mathematical
                     * functions by calculating the result separately and allowing the user to recall
                     * it using the MR button (e.g. "√4" will store the value "2,0" in the variable).
                     *
                     * Since "double.parse" method works only by using "." as decimal symbol we need
                     * to make sure to replace the localized one with it before storing the value and
                     * adding/subtracting to and from it. We must also replace "." with the correct
                     * decimal symbol for locale when recalling stored value from the memory.
                     */
                    var output = eval.evaluate (entry.get_text (), decimal_places);
                    memory_value = double.parse (output.replace (eval.scanner.decimal_symbol, "."));

                    button_mr.set_sensitive (true);
                    button_mc.set_sensitive (true);
                } catch (Core.OUT_ERROR e) {
                    infobar_label.label = e.message;
                    infobar.revealed = true;
                }
            }
        }

        // Addition and subtraction to and from memory value are done silently,
        // updating the value without informing the user, as in real-life calculators.
        private void button_memory_add_clicked () {
            if (entry.get_text () != "") {
                try {
                    var output = eval.evaluate (entry.get_text (), decimal_places);
                    memory_value += double.parse (output.replace (eval.scanner.decimal_symbol, "."));
                } catch (Core.OUT_ERROR e) {
                    infobar_label.label = e.message;
                    infobar.revealed = true;
                }
            }
        }

        private void button_memory_subtract_clicked () {
            if (entry.get_text () != "") {
                try {
                    var output = eval.evaluate (entry.get_text (), decimal_places);
                    memory_value -= double.parse (output.replace (eval.scanner.decimal_symbol, "."));
                } catch (Core.OUT_ERROR e) {
                    infobar_label.label = e.message;
                    infobar.revealed = true;
                }
            }
        }

        private void button_memory_clear_clicked () {
            memory_value = 0;
            button_mr.sensitive = false;
            button_mc.sensitive = false;
        }

        private void button_gt_clicked () {
            action_clear ();

            double grand_total = 0;
            history.foreach ((list_entry) => {
                grand_total += double.parse (list_entry.output.replace (eval.scanner.decimal_symbol, "."));
            });

            entry.set_text (number_to_string (grand_total));
            entry.set_position (grand_total.to_string ().length);
        }

        /* Method taken from "Evaluation.vala" to limit the number of digits to be shown
         * and to strip all trailing zeroes because the last decimals may be innacurate.
         *
         * Since the application has a precision of nine decimal numbers it makes
         * sense to apply the same criterion for the value stored in memory as well.
         */
        private string number_to_string (double number) {
            string shortened_number = ("%.9f".printf (number));
            string number_localized = shortened_number.replace (".", eval.scanner.decimal_symbol);

            /* Remove trailing 0s or decimal symbol */
            while (number_localized.has_suffix ("0")) {
                number_localized = number_localized.slice (0, -1);
            }
            if (number_localized.has_suffix (eval.scanner.decimal_symbol)) {
                number_localized = number_localized.slice (0, -1);
            }

            /* Insert separator symbol in large numbers */
            var builder = new StringBuilder (number_localized);
            var decimal_pos = number_localized.last_index_of (eval.scanner.decimal_symbol);
            if (decimal_pos == -1) {
                decimal_pos = number_localized.length;
            }

            int end_position = 0;
            if (number_localized.has_prefix ("-")) {
                end_position = 1;
            }
            for (int i = decimal_pos - 3; i > end_position; i -= 3) {
                builder.insert (i, eval.scanner.separator_symbol);
            }

            return builder.str;
        }

        private void action_clear () {
            position = 0;
            entry.set_text ("");
            set_focus (entry);
            remove_error ();

            entry.grab_focus ();
            entry.set_position (position);
        }

        private void button_ans_clicked () {
            position = entry.get_position ();
            if ((int) history.length () > 0) {
                unowned List<History?> last = history.last ();
                history_added (last.data.output.to_string ());
            }
        }

        private void toggle_grid (Gtk.ToggleButton button) {
            position = entry.get_position ();
            if (button.get_active ()) {
                /* Show extended functionality */
                button.image = extended_img_2;
                button.tooltip_text = _("Hide extended functionality");
                extended_revealer.set_reveal_child (true);
            } else {
                /* Hide extended functionality */
                button.image = extended_img_1;
                button.tooltip_text = _("Show extended functionality");
                extended_revealer.set_reveal_child (false);
            }
            /* Focusing button_calc because without a new focus it will cause weird window drawing problems. */
            entry.grab_focus ();
            entry.set_position (position);
        }

        private void show_history (Gtk.Button button) {
            position = entry.get_position ();

            history_dialog = new HistoryDialog (history);
            history_dialog.set_transient_for (this);
            history_dialog.added.connect (history_added);
            history_dialog.clear_history.connect (() => {
                history.foreach ((entry) => {
                    history.delete_link (history.find (entry));
                });
                button_ans.sensitive = false;
            });
            history_dialog.hide.connect (() => {
                button_history.sensitive = history != null;
            });
        }

        private void update_history_dialog (History entry) {
            if (history_dialog != null) {
                history_dialog.append (entry);
            }
        }

        private void history_added (string input) {
            entry.insert_at_cursor (input);
            position += input.length;
            entry.grab_focus ();
            entry.set_position (position);
        }

        private void remove_error () {
            infobar.revealed = false;
        }

        private bool key_pressed (Gdk.EventKey key) {
            bool retval = false;
            switch (key.keyval) {
                case Gdk.Key.KP_Decimal:
                case Gdk.Key.KP_Separator:
                case Gdk.Key.decimalpoint:
                case Gdk.Key.period:
                case Gdk.Key.comma:
                    unowned string new_decimal = Posix.nl_langinfo (Posix.NLItem.RADIXCHAR);
                    entry.insert_at_cursor (new_decimal);
                    key.keyval = Gdk.Key.Right;
                    break;
                case Gdk.Key.KP_Divide:
                case Gdk.Key.slash:
                    key.keyval = Gdk.Key.division;
                    break;
                case Gdk.Key.KP_Multiply:
                case Gdk.Key.asterisk:
                    key.keyval = Gdk.Key.multiply;
                    break;
                case Gdk.Key.KP_Subtract:
                case Gdk.Key.minus:
                    regular_button_clicked ("−");
                    retval = true;
                    break;
            }

            return retval;
        }

        public override bool configure_event (Gdk.EventConfigure event) {
            if (configure_id != 0) {
                GLib.Source.remove (configure_id);
            }

            configure_id = Timeout.add (100, () => {
                configure_id = 0;

                int x_pos, y_pos;
                get_position (out x_pos, out y_pos);
                settings.set ("window-position", "(ii)", x_pos, y_pos);

                return false;
            });

            return base.configure_event (event);
        }
    }
}
