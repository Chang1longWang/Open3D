// ----------------------------------------------------------------------------
// -                        Open3D: www.open3d.org                            -
// ----------------------------------------------------------------------------
// The MIT License (MIT)
//
// Copyright (c) 2018 www.open3d.org
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
// IN THE SOFTWARE.
// ----------------------------------------------------------------------------

#include "Menu.h"  // defines GUI_USE_NATIVE_MENUS

#if GUI_USE_NATIVE_MENUS

#import "AppKit/AppKit.h"

#include "Application.h"

#include <string>
#include <vector>

@interface Open3DRunnable : NSObject
{
    std::function<void()> action_;
}
@end

@implementation Open3DRunnable
- (id)initWithFunction: (std::function<void()>)f {
    self = [super init];
    if (self) {
        action_ = f;
    }
    return self;
}

- (void)run {
    action_();
}
@end

namespace open3d {
namespace gui {

struct Menu::Impl {
    NSMenu *menu;
    std::vector<std::shared_ptr<Menu>> submenus;

    NSMenuItem* FindMenuItem(ItemId itemId) const {

        auto item = [this->menu itemWithTag:itemId];
        if (item != nil) {
            return item;
        }
        // Not sure if -itemWithTag searches recursively
        for (auto sm : this->submenus) {
            item = sm->impl_->FindMenuItem(itemId);
            if (item != nil) {
                return item;
            }
        }

        return nil;
    }

};

Menu::Menu()
: impl_(new Menu::Impl()) {
    impl_->menu = [[NSMenu alloc] initWithTitle:@""];
    impl_->menu.autoenablesItems = NO;
}

Menu::~Menu() {} // ARC will automatically release impl_->menu

void* Menu::GetNativePointer() { return impl_->menu; }

void Menu::AddItem(const char *name,
                   const char *shortcut,
                   ItemId itemId /*= NO_ITEM*/) {
    NSString *objcShortcut;
    if (!shortcut) {
        objcShortcut = @"";
    } else {
        objcShortcut = [NSString stringWithUTF8String:shortcut];
    }
    auto item = [[NSMenuItem alloc]
                 initWithTitle:[NSString stringWithUTF8String:name]
                        action:@selector(run)
                 keyEquivalent:objcShortcut];
    item.target = [[Open3DRunnable alloc] initWithFunction:[itemId]() {
        Application::GetInstance().OnMenuItemSelected(itemId);
    }];
    item.tag = itemId;
    [impl_->menu addItem:item];
}

void Menu::AddMenu(const char *name, std::shared_ptr<Menu> submenu) {
    submenu->impl_->menu.title = [NSString stringWithUTF8String:name];
    auto item = [[NSMenuItem alloc]
                 initWithTitle:[NSString stringWithUTF8String:name]
                        action:nil
                 keyEquivalent:@""];
    [impl_->menu addItem:item];
    [impl_->menu setSubmenu:submenu->impl_->menu forItem:item];
    impl_->submenus.push_back(submenu);
}

void Menu::AddSeparator() {
    [impl_->menu addItem: [NSMenuItem separatorItem]];
}

bool Menu::IsEnabled(ItemId itemId) const {
    NSMenuItem *item = impl_->FindMenuItem(itemId);
    if (item) {
        return (item.enabled == YES ? true : false);
    }
    return false;
}

void Menu::SetEnabled(ItemId itemId, bool enabled) {
    NSMenuItem *item = impl_->FindMenuItem(itemId);
    if (item) {
        item.enabled = (enabled ? YES : NO);
    }
}

bool Menu::IsChecked(ItemId itemId) const {
    NSMenuItem *item = impl_->FindMenuItem(itemId);
    if (item) {
        return (item.state == NSControlStateValueOn);
    }
    return false;
}

void Menu::SetChecked(ItemId itemId, bool checked) {
    NSMenuItem *item = impl_->FindMenuItem(itemId);
    if (item) {
        item.state = (checked ? NSControlStateValueOn
                              : NSControlStateValueOff);
    }
}

int Menu::CalcHeight(const Theme &theme) const {
    return 0;  // menu is not part of window on macOS
}

Menu::ItemId Menu::DrawMenuBar(const DrawContext &context, bool isEnabled) {
    return NO_ITEM;
}

Menu::ItemId Menu::Draw(const DrawContext &context,
                        const char *name,
                        bool isEnabled) {
    return NO_ITEM;
}

}  // namespace gui
}  // namespace open3d

#endif  // GUI_USE_NATIVE_MENUS