// @flow
import React from 'react';
import {mount, shallow} from 'enzyme';
import MediaLinkTypeOverlay from '../../overlays/MediaLinkTypeOverlay';

jest.mock('sulu-admin-bundle/utils/Translator', () => ({
    translate: jest.fn((key) => key),
}));

test('Render overlay with minimal config', () => {
    const response = {
        ok: true,
        json: jest.fn(),
    };
    const promise = new Promise((resolve) => resolve(response));

    window.fetch = jest.fn();
    window.fetch.mockReturnValue(promise);

    const mediaLinkTypeOverlay = mount(
        <MediaLinkTypeOverlay
            href={undefined}
            onCancel={jest.fn()}
            onConfirm={jest.fn()}
            onHrefChange={jest.fn()}
            open={true}
        />
    );

    expect(mediaLinkTypeOverlay.find('Form').render()).toMatchSnapshot();
});

test('Render overlay with invalid href type', () => {
    expect(() => shallow(
        <MediaLinkTypeOverlay
            href="1234"
            onCancel={jest.fn()}
            onConfirm={jest.fn()}
            onHrefChange={jest.fn()}
            open={true}
            options={undefined}
        />
    )).toThrow('The id of a media should always be a number!');
});

test('Render overlay with target enabled', () => {
    const response = {
        ok: true,
        json: jest.fn(),
    };
    const promise = new Promise((resolve) => resolve(response));

    window.fetch = jest.fn();
    window.fetch.mockReturnValue(promise);

    const mediaLinkTypeOverlay = mount(
        <MediaLinkTypeOverlay
            href={undefined}
            onCancel={jest.fn()}
            onConfirm={jest.fn()}
            onHrefChange={jest.fn()}
            onTargetChange={jest.fn()}
            open={true}
        />
    );

    expect(mediaLinkTypeOverlay.find('Form').render()).toMatchSnapshot();
});

test('Render overlay with title enabled', () => {
    const response = {
        ok: true,
        json: jest.fn(),
    };
    const promise = new Promise((resolve) => resolve(response));

    window.fetch = jest.fn();
    window.fetch.mockReturnValue(promise);

    const mediaLinkTypeOverlay = mount(
        <MediaLinkTypeOverlay
            href={undefined}
            onCancel={jest.fn()}
            onConfirm={jest.fn()}
            onHrefChange={jest.fn()}
            onTitleChange={jest.fn()}
            open={true}
        />
    );

    expect(mediaLinkTypeOverlay.find('Form').render()).toMatchSnapshot();
});

test('Delegate only id to onHrefChange method', () => {
    const response = {
        ok: true,
        json: jest.fn(),
    };
    const promise = new Promise((resolve) => resolve(response));

    window.fetch = jest.fn();
    window.fetch.mockReturnValue(promise);

    const hrefChangeSpy = jest.fn();

    const mediaLinkTypeOverlay = mount(
        <MediaLinkTypeOverlay
            href={undefined}
            onCancel={jest.fn()}
            onConfirm={jest.fn()}
            onHrefChange={hrefChangeSpy}
            onTitleChange={jest.fn()}
            open={true}
        />
    );

    mediaLinkTypeOverlay.find('SingleMediaSelection').get(0).props.onChange({id: 1}, undefined);
    expect(hrefChangeSpy).toBeCalledWith(1, undefined);
});
